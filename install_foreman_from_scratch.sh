

# Author Mamun Rashid 6.2017
echo
echo This is an idempodent script to install foreman from on fresh Redhat 7.3 system.
echo
echo 6.26.2017: this script needs 2  bug fixes: -Mamun
echo  a. save the admin password from foreman-installer script to a file
echo  b. change  the decision criteria to run foreman-installer to count how many forman and puppet yum packages are installed: about 10 total
echo
echo ENTER to continue
echo n
sleep 1


# VARIABLES SECTION
#
#
# sdata1 keeps base64 encrypted username 
UFILE=/var/tmp/sdata1
if [ -f  $UFILE ]
 then
   echo $UFILE file exists. thats good.
   REDHAT_U=`cat $UFILE | base64 --decode`
 else
   echo $UFILE file does not exist. It needs to have base64-encrypted username for Redhat
   echo existing
   exit 
fi

PFILE=/var/tmp/sdata2
if [ -f  $PFILE ]
 then
   echo $PFILE file exists. thats good.
   REDHAT_P=`cat $PFILE | base64 --decode`
 else
   echo $PFILE file does not exist. It needs to have base64-encrypted username for Redhat
   echo existing
   exit 
fi


#echo $REDHAT_U
#echo $REDHAT_P


IPA=`ifconfig eth0 | grep inet | grep netmask | awk '{print $2'}`
echo IP address $IPA
SHORT=`hostname -s`
echo Short Host Name: $SHORT
FQDN=`hostname -f`
echo Long Host Name: $FQDN



# HOSTS FILE
COUNT1=`grep $IPA /etc/hosts | grep $FQDN | grep $SHORT | wc -l`
if [ "$COUNT1" -gt "0" ];
 then
   echo hosts file looks good already
 else
   echo hosts file does not FQDN and short hostname. exiting.
   echo "fxing hosts file"
   echo adding FQDN and short host name to hosts file
   echo $IPA $FQDN $SHORT >> /etc/hosts
   echo checking hosts file
   COUNT1=`grep $IPA /etc/hosts | grep $FQDN | grep $SHORT | wc -l`
fi

if [ "$COUNT1" -gt "0" ];
 then
   echo hosts file looks good
 else
   echo hosts file does not FQDN and short hostname. exiting.
   exit 3
fi


# REDHAT SUBSCRIPTION
#pre-check and execution
echo checking registration
COUNT2=`subscription-manager version | grep type | grep "not registered" | wc -l`
if [ "$COUNT2" -eq "1" ];
 then
   echo this machine is not registered with Redhat
   echo Registering and auto-attaching
   subscription-manager register --username $REDHAT_U --password $REDHAT_P --force --auto-attach
 else
   echo this machine is registered with Redhat
fi
#post-check
COUNT2=`subscription-manager version | grep type | grep "not registered" | wc -l`
if [ "$COUNT2" -eq "1" ];
 then
   echo this machine is not registered with Redhat STILL. exiting.
   exit 3
 else
   echo this machine is registered with Redhat
fi


# ATTACHMENT CHECK
COUNT3=`subscription-manager repos --list | grep Name | wc -l`
if [ "$COUNT3" -gt "50" ];
 then
   echo we have more than 50 repos. we are probbaly good to proceed.
 else
   echo this machine has less 50 repos. expected around 100. executing auto attach command
   subscription-manager attach --auto
fi
#post-check
COUNT3=`subscription-manager repos --list | grep Name | wc -l`
if [ "$COUNT3" -gt "50" ];
 then
   echo we have more than 50 repos. we are probbaly good to proceed.
 else
   echo ERROR:this machine has less 50 repos. still. not good. This probbaly means we have exhaused alll our licenses. existing.
   exit 3
fi





# OPTIONAL REPO THAT IS REQUIRED FOR FOREMAN
#pre-check
COUNT4=`yum repolist all | grep rhel-7-server-optional | grep -v beta | grep -v debug | grep -v source | grep -v fastrack| grep enabled|wc -l`
if [ "$COUNT4" -gt "0" ];
 then
   echo rhel-7-server-optional repo is enabled. we are good to proceed further.
 else
   echo rhel-7-server-optional repo is disabled. enabling.
   subscription-manager repos --enable=rhel-7-server-optional-rpms
fi
#post-check
COUNT4=`yum repolist all | grep rhel-7-server-optional | grep -v beta | grep -v debug | grep -v source | grep -v fastrack| grep enabled|wc -l`
if [ "$COUNT4" -gt "0" ];
 then
   echo rhel-7-server-optional repo is enabled. we are good to proceed further.
 else
   echo ERROR:rhel-7-server-optional repo is disabled. still. existing.
   exit 4
fi



# GPG KEY
echo improting GPG KEY
sudo rpm --import https://www.centos.org/keys/RPM-GPG-KEY-CentOS-7
if [ "$?" -eq "0" ];
 then
   echo import succeeded. good to proceed further.
 else
   echo ERROR:rpm import RPM-GPG-KEY-CentOS-7 key failed. Exiting.
   exit 5
fi



# PUPPETLABS-RELEASE-PC1 
#precheck and execution
PCK6=puppetlabs-release-pc1.noarch
COUNT6=`yum list installed | grep $PCK6 | wc -l`
if [ "$COUNT6" -gt "0" ];
 then
   echo  $PCK6 package already installed. good to proceeded further.
 else
   echo installing $PCK6
   yum -y install https://yum.puppetlabs.com/puppetlabs-release-pc1-el-7.noarch.rpm
fi
#post-check
COUNT6=`yum list installed | grep puppetlabs-release-pc1.noarch | wc -l`
if [ "$COUNT6" -gt "0" ];
 then
   echo  $PCK6 package already installed. good to proceeded further.
 else
   echo ERROR: $PCK6 STILL not installed.exiting.
   exit 6
fi






# EPEL-RELEASE-LATEST-7.NOARCH
#precheck and execution
PCK7=epel-release.noarch
COUNT7=`yum list installed | grep $PCK7 | wc -l`
if [ "$COUNT7" -gt "0" ];
 then
   echo  $PCK7 package already installed. good to proceeded further.
 else
   echo installing $PCK7
   yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
fi
#post-check
COUNT7=`yum list installed | grep $PCK7 | wc -l`
if [ "$COUNT7" -gt "0" ];
 then
   echo  $PCK7 package already installed. good to proceeded further.
 else
   echo ERROR: $PCK7 STILL not installed.exiting.
   exit 7
fi



# FOREMAN_RELEASE
#precheck and execution
PCK8=foreman-release
COUNT8=`yum list installed | grep $PCK8 | wc -l`
if [ "$COUNT8" -gt "0" ];
 then
   echo  $PCK8 package already installed. good to proceeded further.
 else
   echo installing $PCK8
   yum -y install https://yum.theforeman.org/releases/1.15/el7/x86_64/foreman-release.rpm
fi
#post-check
COUNT8=`yum list installed | grep $PCK8 | wc -l`
if [ "$COUNT8" -gt "0" ];
 then
   echo  $PCK8 package already installed. good to proceeded further.
 else
   echo ERROR: $PCK8 STILL not installed.exiting.
   exit 8
fi


# FOREMAN_INSTALLER
#precheck and execution
PCK9=foreman-installer
COUNT9=`yum list installed | grep $PCK9 | wc -l`
if [ "$COUNT9" -gt "0" ];
 then
   echo  $PCK9 package already installed. good to proceeded further.
 else
   echo installing $PCK9
   yum -y install $PCK9
fi
#post-check
COUNT9=`yum list installed | grep $PCK9 | wc -l`
if [ "$COUNT9" -gt "0" ];
 then
   echo  $PCK9 package already installed. good to proceeded further.
 else
   echo ERROR: $PCK9 STILL not installed.exiting.
   exit 9
fi














# DECISION TO RUN foreman-installer or not
#
INS_FILE=/var/log/foreman-installer/foreman.log
if [ -f  $INS_FILE ]
 then
   echo $INS_FILE file exists
   LOG_FILE=1
 else
   echo $INS_FILE file does not exist
   LOG_FILE=0
fi

COUNTP=`ps -ef | grep foreman | grep -v grep |wc -l`
echo $COUNTP
if [ $COUNTP -gt "2" ]; then
   echo 3 or more foreman processes running. probbaly means install is complete
   PROCESS=1
else
   echo 2 or less foreman processes running. probably means install is NOT complete.
   PROCESS=0
fi

if [ $LOG_FILE -eq "0" ] && [ $PROCESS -eq "0" ]; then
      echo  $INS_FILE log file does not exist and foreman process is not running
      echo safe to run foreman_installer
      echo running foreman-installer
      sleep 2
      foreman-installer
      CAPTURE=$?
      echo
      echo foreman-installer executed
      echo
      if [ "$CAPTURE" -gt "0" ];
       then
         echo  WARNING:foreman-installer probbaly did not succeed. exit-code non-zero.
         sleep 1
       else
         echo Looks like foreman-installer succeeded
         sleep 1
         echo post-check: checking that http and https are now open on this host. If not, foreman is not fully up and running.
         netstat -a | grep LISTEN | grep -v ING | grep http
       fi
  else
      echo either foreman-installer exists OR foreman process is already running
      echo NOT running foreman-installer
fi




