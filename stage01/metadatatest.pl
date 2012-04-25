#!/usr/bin/perl

require "ec2ops.pl";

my $account = shift @ARGV || "eucalyptus";
my $user = shift @ARGV || "admin";
my @metatests = @ARGV;

# need to add randomness, for now, until account/user group/keypair
# conflicts are resolved

$rando = int(rand(10)) . int(rand(10)) . int(rand(10));
if ($account ne "eucalyptus") {
    $account .= "$rando";
}
if ($user ne "admin") {
    $user .= "$rando";
}
$newgroup = "mdgroup$rando";
$newkeyp = "mdkey$rando";

parse_input();
print "SUCCESS: parsed input\n";

if (!$ismanaged) {
    doexit(0, "SUCCESS: Network mode does not support metadata service, skipping: EXITING SUCCESS\n");
}

setlibsleep(2);
print "SUCCESS: set sleep time for each lib call\n";

setremote($masters{"CLC"});
print "SUCCESS: set remote CLC: masterclc=$masters{CLC}\n";

discover_emis();
print "SUCCESS: discovered loaded image: current=$current_artifacts{instancestoreemi}, all=$static_artifacts{instancestoreemis}\n";

discover_zones();
print "SUCCESS: discovered available zone: current=$current_artifacts{availabilityzone}, all=$static_artifacts{availabilityzones}\n";

if ( ($account ne "eucalyptus") && ($user ne "admin") ) {
# create new account/user and get credentials
    create_account_and_user($account, $user);
    print "SUCCESS: account/user $current_artifacts{account}/$current_artifacts{user}\n";
    
    grant_allpolicy($account, $user);
    print "SUCCESS: granted $account/$user all policy permissions\n";
    
    get_credentials($account, $user);
    print "SUCCESS: downloaded and unpacked credentials\n";
    
    source_credentials($account, $user);
    print "SUCCESS: will now act as account/user $account/$user\n";
}
# moving along

add_keypair("$newkeyp");
print "SUCCESS: added new keypair: $current_artifacts{keypair}, $current_artifacts{keypairfile}\n";

add_group("$newgroup");
print "SUCCESS: added group: $current_artifacts{group}\n";

authorize_ssh();
print "SUCCESS: authorized ssh access to VM\n";

run_instances(1);
print "SUCCESS: ran instance: $current_artifacts{instance}\n";

wait_for_instance();
print "SUCCESS: instance went to running: $current_artifacts{instancestate}\n";

wait_for_instance_ip();
print "SUCCESS: instance got public IP: $current_artifacts{instanceip}\n";

$oldrunat = $runat;
setrunat("runat 300");
run_instance_command("echo '192.168.7.65 archive.ubuntu.com' >> /etc/hosts; echo '192.168.7.65 security.ubuntu.com' >> /etc/hosts; apt-get update; apt-get install -y curl; true");
print "SUCCESS: pre-test setup success\n";
setrunat("$oldrunat");

foreach $metatest (@metatests) {
    copy_to_instance("./$metatest");
    print "SUCCESS: copied $metatest to instance\n";

    run_instance_command("./$metatest");
    print "SUCCESS: ran $metatest without fail\n";
}
print "SUCCESS: all metadata tests passed\n";

doexit(0, "EXITING SUCCESS\n");
