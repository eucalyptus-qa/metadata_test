#!/usr/bin/python

import urllib
import sys

totalrc = 0

def treewalk(newbaseurl, metakeys, depth):
    if ( depth > 10 ):
        return(0)

    for k in metakeys:

        url = newbaseurl + "/" + k
        url = url.replace('//', '/')
        url = url.replace('http:/', 'http://')
        print '\t'*depth + "'%s'" % k

        valurl = urllib.urlopen(url)
        val = valurl.read()
        if (k.find("/") != -1):
            treewalk(url, val.split("\n"), depth+1)
        else:
            print '\t'*depth + "\t'" + val + "'" + "  (URL " + url + ")"
        valurl.close()
            
    return(0)

print "Performing meta-data tree walk: "
baseurl = "http://169.254.169.254/latest/meta-data/"
metadata = urllib.urlopen(baseurl)
keys = metadata.read()
rc = treewalk(baseurl, keys.split("\n"), 1)
metadata.close()
totalrc = totalrc + rc
print "Done with meta-data tree walk: %d errors encountered" % rc

print ""

print "Performing static meta-data key queries:"
META_DATA_KEYS = ['block-device-mapping/', 'security-groups', 'ami-manifest-path', 'public-keys/', 'ramdisk-id', 'reservation-id', 'public-keys/0/', 'ami-launch-index', 'kernel-id', 'instance-type', 'local-hostname', 'local-ipv4', 'hostname', 'public-ipv4', 'instance-id', 'public-hostname', 'ami-id', 'placement/']
baseurl = "http://169.254.169.254/latest/meta-data/"
metadata = urllib.urlopen(baseurl)
keys = metadata.read()

rc = 0
for k in META_DATA_KEYS:
    if k in keys:
        print "key found: " + k
    else:
        print "key not found: " + k
        rc = rc + 1

totalrc = totalrc + rc
metadata.close()
print "Done with static meta-data key queries: %d errors encountered" % rc

print ""

print "Performing error response queries:"

BAD_META_DATA_KEYS = ['foobar', 'barfoo', 'nou', 'neil']
rc = 0
baseurl = "http://169.254.169.254/latest/meta-data/"

#TODO: need a better way to test for 'correct' failures from metadata (404? 404 in HTML returned? empty string?)
for k in BAD_META_DATA_KEYS:
    url = baseurl + k
    metadata = urllib.urlopen(url)
    keys = metadata.read()
    print "'" + keys + "' URL: " + url
    if (keys.find("failed") < 0):
        print "\t should have failed"
        rc = rc + 1

    metadata.close()


totalrc = totalrc + rc
print "Done with error response queries: %d errors encountered" % rc

if (totalrc != 0):
    print 'TEST FAILED'
    sys.exit(1)

print "TEST SUCCESS"

sys.exit(0)
