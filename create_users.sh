#!/usr/bin/env bash

# Check if the script is running as root
if [[ "$EUID" -ne 0 ]]; then
  echo "Error: This script needs to run as root. Use sudo"
  exit 1
fi

# Create necessary directories if they don't exist
if [ ! -d /var/log ] || [ ! -d /var/secure ]; then
    mkdir -p /var/secure
    mkdir -p /var/log
fi

log_file="/var/log/user_management.log"
password_file="/var/secure/user_passwords.csv"

log_message() {
    local message="$1"
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $message" >> $log_file
}

# Check for correct number of arguments
if [ "$#" -ne 1 ]; then
    arg_err="Usage: $0 <file_path>"
    echo "$arg_err"
    log_message "$arg_err"
    exit 1
fi  

employee_file=$1

# Check if the employee file exists
if [ ! -f "$employee_file" ]; then
    file_missing_err="Error: File '$employee_file' not found."
    echo "$file_missing_err"
    log_message "$file_missing_err"
    exit 1
fi

# Secure password file
log_message "Securing $password_file"
if [ ! -f $password_file ]; then
	echo "User,password" >> $password_file
	chmod 600 $password_file
fi	

shell="/bin/bash"
echo "--------------------"
echo "=> Reading $employee_file..."
echo "--------------------"
echo ""
log_message "Reading $employee_file"

while IFS=';' read -r user groups; do
    # Read users and groups from the .txt file
    user=$(echo "$user" | xargs)
    groups=$(echo "$groups" | xargs)
    
    if [[ -z "$user" || -z "$groups" ]]; then
        newline_err="Skipping invalid line in the input file"
        echo "$newline_err"
        log_message "$newline_err"
        continue
    fi
    
    echo "=> Processing user: $user"
    log_message "Processing user: $user"
    IFS=',' read -r -a group_array <<< "$groups"

    for i in "${!group_array[@]}"; do
        group_array[$i]=$(echo "${group_array[$i]}" | xargs)
    done
    
    echo "=> Groups for $user: ${group_array[*]}"
    log_message "Groups for $user: ${group_array[*]}"
    
    # Create group with the same name as the user
    if getent group "$user" &>/dev/null; then
        echo "Group $user already exists."
        log_message "Group $user already exists."
    else
        if groupadd "$user"; then
            echo "=> Group $user created."
            log_message "Group $user created."
        else
            echo "Error creating group $user."
            log_message "Error creating group $user."
            continue
        fi
    fi
    
    # Creating user, user's home directory and assigning a randomly generated password
    echo "=> Creating user: $user..."
    log_message "Creating user: $user"
    if id "$user" &>/dev/null; then
        echo "User $user already exists."
        log_message "User $user already exists."
    else
        if useradd -m -s "$shell" -g "$user" "$user"; then
            echo "=> User $user created with home directory /home/$user."
            log_message "User $user created with home directory /home/$user."
            
            password=$(head /dev/urandom | tr -dc A-Za-z0-9 | fold -w 6 | head -n 1)
            if echo "$user:$password" | chpasswd; then
                echo "$user,$password" >> $password_file
                echo "=> Password set for $user"
                log_message "Password set for $user"
            else
                echo "Error setting password for $user."
                log_message "Error setting password for $user."
                continue
            fi
        else
            echo "Error creating user $user."
            log_message "Error creating user $user."
            continue
        fi
    fi

    # Add the user to other specified groups
    for group in "${group_array[@]}"; do
        if getent group "$group" &>/dev/null; then
            echo "Group $group already exists."
            log_message "Group $group already exists."
        else
            if groupadd "$group"; then
                echo "Group $group created."
                log_message "Group $group created."
            else
                echo "Error creating group $group."
                log_message "Error creating group $group."
                continue
            fi
        fi
        if usermod -aG "$group" "$user"; then
            echo "=> Added $user to group $group."
            log_message "Added $user to group $group."
        else
            echo "Error adding $user to group $group."
            log_message "Error adding $user to group $group."
            continue
        fi
    done
    
    echo "--------------------"
done < "$employee_file"

echo "Operation Successful"
log_message "Operation Successful"
exit 0
