# foreman_install_on_rehdat
Just a idempotent script that will install Foreman on Redhat from scratch. This is useful since Foreman Installation is still not very smooth when you do by hand.

This script requires that you save base64 coded username for your Redhat subscription service in /var/tmp/sdata1 AND
                     that you save base64 coded password for your Redhat subscription service in /var/tmp/sdata2 
                     before running this script.
                     
                     
                     e.g. echo "foo" | base64 > /var/tmp/sdata1
                          echo "bar" | base64 > /var/tmp/sdata2
                          
 Once you have those two files created, you can copy this script in /var/tmp/ (or any other location) and then:
 
 sudo /var/tmp/foreman_install_on_redhat
 
 
 This script runs pre-check and post-check on each step. If it fails, it will tell you exactly why.
                          
                          -Mamun Rashid @mamunr7
