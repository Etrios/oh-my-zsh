
######################### aliases ####################################
##Don't alias grep until after sourcing the files above, could get bad version
##of grep that doesn't understand --color
alias grep='nocorrect grep --color=auto'

alias ls='ls --color=auto'
alias ll='ls -lh'
alias vi='vim'

############
#
# Functions
#

alias pullall='for i in *; do; (cd $i; git pull;) done;'
alias idea='/opt/idea/bin/idea.sh'
alias sld='sudo -u ldapp'
alias slc='sudo -u ldcpapp'
alias mcs='mysql -ucloud -pscape'


# lcfiles - Lowercase all files in the current directory
lcfiles() {
	print -n 'Really lowercase all files? (y/n) '
	if read -q ; then
		for i in * ; do
			mv $i $i:l
	done
	fi
}

# Compression shortcuts

#tar.gz
tg() {
	tarfile=$1
	shift
	tar -czvf $tarfile $@
}

#tar.bz2
tb() {
	tar --bzip2 -cvf $tarfile $@
}

# Extract various compression formats
extract () {
     if [ -f $1 ] ; then
         case $1 in
             *.tar.bz2)   tar xjf $1        ;;
             *.tar.gz)    tar xzf $1     ;;
             *.bz2)       bunzip2 $1       ;;
             *.rar)       rar x $1     ;;
             *.gz)        gunzip $1     ;;
             *.tar)       tar xf $1        ;;
             *.tbz2)      tar xjf $1      ;;
             *.tgz)       tar xzf $1       ;;
             *.zip)       unzip $1     ;;
             *.Z)         uncompress $1  ;;
             *.7z)        7z x $1    ;;
             *)           echo "'$1' cannot be extracted via extract()" ;;
         esac
     else
         echo "'$1' is not a valid file"
     fi
}

# Weather by us zip code - Can be called two ways # weather 50315 # weather "Des Moines"
weather ()
{
declare -a WEATHERARRAY
WEATHERARRAY=( `elinks -dump "http://www.google.com/search?hl=en&lr=&client=firefox-a&rls=org.mozilla%3Aen-US%3Aofficial&q=weather+${1}&btnG=Search" | grep -A 5 -m 1 "Weather for" | sed 's;\[26\]Add to iGoogle\[27\]IMG;;g'`)
echo ${WEATHERARRAY[@]}
}

#copy and go to dir
cpg (){
  if [ -d "$2" ];then
    cp $1 $2 && cd $2
  else
    cp $1 $2
  fi
}

#move and go to dir
mvg (){
  if [ -d "$2" ];then
    mv $1 $2 && cd $2
  else
    mv $1 $2
  fi
}

#dirsize - finds directory sizes and lists them for the current directory
dirsize ()
{
du -shx * .[a-zA-Z0-9_]* 2> /dev/null | \
egrep '^ *[0-9.]*[MG]' | sort -n > /tmp/list
egrep '^ *[0-9.]*M' /tmp/list
egrep '^ *[0-9.]*G' /tmp/list
rm /tmp/list
}

#myip - finds your current IP if your connected to the internet
myip ()
{
elinks -dump http://checkip.dyndns.org:8245/ | awk '{ print $4 }' | sed '/^$/d; s/^[ ]*//g; s/[ ]*$//g' 
}

#netinfo - shows network information for your system
netinfo ()
{
echo "--------------- Network Information ---------------"
/sbin/ifconfig | awk /'inet addr/ {print $2}'
/sbin/ifconfig | awk /'Bcast/ {print $3}'
/sbin/ifconfig | awk /'inet addr/ {print $4}'
/sbin/ifconfig | awk /'HWaddr/ {print $4,$5}'
myip=`elinks -dump http://checkip.dyndns.org:8245/ | sed '/^$/d; s/^[ ]*//g; s/[ ]*$//g' `
echo "${myip}"
echo "---------------------------------------------------"
}

#bu - Back Up a file. Usage "bu filename.txt" 
bu () { cp $1 ${1}-`date +%Y%m%d%H%M`.backup ; }

# Pacman search colourised by repository
psc() {
  echo -e "$(pacman -Ss $@ | sed \
       -e 's#core/.*#\\033[1;31m&\\033[0;37m#g' \
       -e 's#extra/.*#\\033[0;32m&\\033[0;37m#g' \
       -e 's#community/.*#\\033[1;35m&\\033[0;37m#g' \
       -e 's#^.*/.* [0-9].*#\\033[0;36m&\\033[0;37m#g' )"
}

