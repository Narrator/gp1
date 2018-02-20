#!/bin/bash

EMP_INFO=/home/scripting_admin/hw2/empinfo.csv
PASSWD_FILE=/etc/passwd
GROUP_FILE=/etc/group

if [ $EUID -ne 0 ]; then
	echo "You need to have super user privileges to run this script. Exiting."
	exit 1;
fi

echo -e "\n"
echo "-------------------------"
echo "<-- Server Admin Menu -->"
echo -e "-------------------------\n"
echo -e "What do you want to do?\n"

echo "1) Add all users from empinfo.csv"
echo "2) Add all groups present in empinfo.csv"
echo "3) Assign all users to their respective groups"
echo "4) Remove all group assignments"
echo "5) Remove all users"
echo "6) Remove all groups"
echo -e "\n"

read -p "Enter your choice [1 - 6] > " action
echo -e "\n"

case $action in
	1) user_added=0
	   user_exists=0

	   while IFS="," read fn ln username group dob ad ci st zi p1 p2 password; do
		user_info=$(grep "^$username:" $PASSWD_FILE)
	   	if [ -n "$user_info" ]; then
	  		echo "User $username exists already. Skipping"
			user_exists=$(($user_exists+1))
	   	else
			useradd $username > /dev/null 2>&1
			cat << EOF | passwd $username
$password
$password
EOF
echo "$password hello"
			# echo "$username":"$password" | chpasswd
			echo "Added user $username with password $password"
			user_added=$(($user_added+1))
	   	fi
	   done < $EMP_INFO

	   echo -e "\n-------------------------"
	   if [ $user_exists -gt 0 ]; then
	   	echo "$user_exists users existed already. They were not added."
	   fi
	   if [ $user_added -gt 0 ]; then
	   	echo "$user_added new users were added"
	   fi
	   echo -e "-------------------------\n"

	   exit 1;;

	2) groups_added=0
	   groups_exists=0

	   while read group; do
		group_info=$(grep "^$group:" $GROUP_FILE)
		if [ -n "$group_info" ]; then
			echo "Group $group exists already. Skipping"
			groups_exists=$(($groups_exists+1))
		else
			groupadd $group > /dev/null 2>&1
			echo "Added new group $group"
			groups_added=$(($groups_added+1))
		fi
	   done < <(tail -n +2 $EMP_INFO | cut -d "," -f 4 | sort | uniq $group)

	   echo -e "\n-------------------------"
	   if [ $groups_added -gt 0 ]; then
		echo "$groups_added new groups were added"
	   fi
	   if [ $groups_exists -gt 0 ]; then
	   	echo "$groups_exists groups existed already. They were not added"
	   fi
	   echo -e "-------------------------\n"

	   exit 1;;

	3) group_assignments=0
	   not_assigned=0

	   while IFS="," read fn ln username group dob ad ci st zi p1 p2 password; do
		user_info=$(grep "^$username:" $PASSWD_FILE)
		group_info=$(grep "^$group:" $GROUP_FILE)
		if [ -n "$user_info" -a -n "$group_info" ]; then
			user_group=$(id -nG "$username" | grep -w "$group")
			if [ -n "$user_group" ]; then
				echo "User $username already belongs to group $group. Skipping"
				not_assigned=$(($not_assigned+1))
			else
				usermod -a -G $group $username > /dev/null 2>&1
				echo "User $username was added to group $group"
				group_assignments=$(($group_assignments+1))
			fi
		else
			echo "User $username or group $group doesn't exist. Skipping"
			not_assigned=$(($not_assigned+1))
		fi
	   done < $EMP_INFO

	   echo -e "\n-------------------------"
	   if [ $group_assignments -gt 0 ]; then
		echo "$group_assignments users were assigned to their respective groups"
	   fi
	   if [ $not_assigned -gt 0 ]; then
		echo "$not_assigned users were not assigned!"
	   fi
	   echo -e "-------------------------\n"

	   exit 1;;

	4) group_dissociations=0
	   not_dissociated=0

	   while IFS="," read fn ln username group dob ad ci st zi p1 p2 password; do
		user_info=$(grep "^$username:" $PASSWD_FILE)
		group_info=$(grep "^$group:" $GROUP_FILE)
		if [ -n "$user_info" -a -n "$group_info" ]; then
			user_group=$(id -nG "$username" | grep -w "$group")
			if [ -n "$user_group" ]; then
				usermod -G "" $username > /dev/null 2>&1
				echo "User $username was removed from group $group"
				group_dissociations=$(($group_dissociations+1))				
			else
				echo "User $username does not belong to group $group. Skipping"
				not_dissociated=$(($not_dissociated+1))
			fi
		else
			echo "User $username or group $group doesn't exist. Skipping"
			not_dissociated=$(($not_dissociated+1))
		fi
	   done < $EMP_INFO

	   echo -e "\n-------------------------"
	   if [ $group_dissociations -gt 0 ]; then
		echo "$group_dissociations users were removed from their respective groups"
	   fi
	   if [ $not_dissociated -gt 0 ]; then
		echo "$not_dissociated users were not removed from any groups"
	   fi
	   echo -e "-------------------------\n"

	   exit 1;;

	5) user_deleted=0
	   user_not_exists=0

	   while IFS="," read fn ln username group dob ad ci st zi p1 p2 password; do
		user_info=$(grep "^$username:" $PASSWD_FILE)
	   	if [ -n "$user_info" ]; then
			userdel $username > /dev/null 2>&1
			echo "User $username was deleted"
			user_deleted=$(($user_deleted+1))
		else
			echo "User $username does not exist"
			user_not_exists=$(($user_not_exists+1))
		fi
	   done < $EMP_INFO

	   echo -e "\n-------------------------"
	   if [ $user_deleted -gt 0 ]; then
		echo "$user_deleted users were deleted"
	   fi
	   if [ $user_not_exists -gt 0 ]; then
	   	echo "$user_not_exists users were not deleted since they don't exist"
	   fi
	   echo -e "-------------------------\n"

	   exit 1;;

	6) gr_deleted=0
	   gr_not_exists=0

	   while read group; do
	   	group_info=$(grep "^$group:" $GROUP_FILE)
		if [ -n "$group_info" ]; then
			groupdel $group > /dev/null 2>&1
			echo "Group $group was deleted"
			gr_deleted=$(($gr_deleted+1))
		else
			echo "Group $group does not exist"
			gr_not_exists=$(($gr_not_exists+1))
		fi
	   done < <(tail -n +2 $EMP_INFO | cut -d "," -f 4 | sort | uniq $group)

	   echo -e "\n-------------------------"
	   if [ $gr_deleted -gt 0 ]; then
	   	echo "$gr_deleted groups were deleted"
	   fi
	   if [ $gr_not_exists -gt 0 ]; then
		echo "$gr_not_exists groups were not deleted since they don't exist"
	   fi
	   echo -e "-------------------------\n"

	   exit 1;;

	*) echo "Not a valid option!"; exit 1;;

esac
