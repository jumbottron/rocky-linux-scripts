#rockywhiptail
#mashley
#!/bin/bash

# Function to display the menu
show_menu() {
    whiptail --title "System Configuration Menu" --menu "Please select an option:" 15 60 8 \
    "1" "Install SSH" \
    "2" "Add sudo user" \
    "3" "Add SFTP user" \
    "4" "Install Docker and Docker Compose" \
    "5" "Disable SELinux" \
    "6" "Check installed version of Docker" \
    "7" "Uninstall Docker and Docker Compose" \
    "8" "Install Portainer" \
    "9" "Add user's private key for SSH" \
    "10" "Install Apache" \
    "11" "Install PostgreSQL" \
    "12" "Install Zabbix agent" \
    "13" "Install Figlet Docker" \
    "14" "Set Firewall Rules For Apache 80/443" \
    "15" "Install Git" \
    "0" "Exit" 3>&1 1>&2 2>&3
}

# Function to install SSH
install_ssh() {
    if [[ $(rpm -q openssh-server) ]]; then
        echo "SSH is already installed."
    else
        echo "Installing SSH..."
        sudo dnf install -y openssh-server
        sudo systemctl start sshd
        sudo systemctl enable sshd
        echo "SSH installed and started."
    fi
}

# Function to add sudo user
add_sudo_user() {
    echo "Please enter the username for the new sudo user:"
    read username
    if [[ $(sudo -lU $username | grep -c "(ALL : ALL)") -ne 0 ]]; then
        echo "User $username is already a sudoer."
    else
        sudo useradd -m -s /bin/bash $username
        sudo passwd $username
        sudo usermod -aG wheel $username
        echo "User $username added to sudo group."
    fi
}

# Function to add SFTP user
add_sftp_user() {
    username=$(whiptail --inputbox "Please enter the username for the new SFTP user:" 10 60 3>&1 1>&2 2>&3)
    exitstatus=$?
    if [ $exitstatus -eq 0 ]; then
        if [[ $(id -nG $username | grep -c sftp) -ne 0 ]]; then
            echo "User $username is already an SFTP user."
        else
            sudo useradd -m -s /bin/false $username
            sudo passwd $username
            sudo usermod -aG sftp $username
            sudo chown root:root /home/$username
            sudo chmod 755 /home/$username
            sudo mkdir /home/$username/files
            sudo chown $username:$username /home/$username/files
            echo "User $username added for SFTP."
        fi
    else
        echo "User creation cancelled."
    fi
}

# Function to install Docker and Docker Compose
install_docker() {
    echo "Installing Docker and Docker Compose..."
    if rpm -q docker-ce docker-ce-cli containerd.io docker-compose >/dev/null 2>&1; then
        echo "Docker and Docker Compose are already installed."
    else
        sudo dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
        sudo dnf install -y docker-ce docker-ce-cli containerd.io
        sudo systemctl start docker
        sudo systemctl enable docker
        sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        echo "Docker and Docker Compose installed and started."
    fi
}

# Function to disable SELinux
disable_selinux() {
    if [[ $(sestatus | grep -c "SELinux status: enabled") -ne 0 ]]; then
        echo "Disabling SELinux..."
        sudo sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
        echo "SELinux disabled. Please reboot the system for the changes to take effect."
    else
        echo "SELinux is already disabled."
    fi
}

# Function to check installed version of Docker
check_docker_version() {
    echo "Checking installed version of Docker..."
    docker version
}

# Function to uninstall Docker and Docker Compose
uninstall_docker() {
    echo "Uninstalling Docker and Docker Compose..."
    if rpm -q docker-ce docker-ce-cli containerd.io docker-compose >/dev/null 2>&1; then
        sudo dnf remove -y docker-ce docker-ce-cli containerd.io
        sudo rm -f /usr/local/bin/docker-compose
        echo "Docker and Docker Compose uninstalled."
    else
        echo "Docker and Docker Compose are not installed."
    fi
}

# Function to install Portainer
install_portainer() {
    if [[ $(sudo docker ps --filter name=portainer --format "{{.Names}}") == "portainer" ]]; then
        echo "Portainer is already installed."
    else
        echo "Installing Portainer..."
        sudo docker volume create portainer_data
        sudo docker run -d -p 8000:8000 -p 9000:9000 --name portainer --restart always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce
        sleep 5 # wait for Portainer to start up
        if curl --output /dev/null --silent --head --fail http://localhost:9000; then
            echo "Portainer installed and started."
        else
            echo "Error: Portainer installation failed or web interface not accessible."
        fi
    fi
}

# Function to add user's private key for SSH
add_ssh_key() {
    echo "Please enter the username for the user who's private key you want to add:"
    read username
    if id "$username" >/dev/null 2>&1; then
        echo "User $username already exists."
    else
        sudo useradd -m -s /bin/bash $username
        sudo passwd $username
        sudo usermod -aG wheel $username
        echo "User $username added."
    fi
    sudo mkdir /home/$username/.ssh
    sudo chmod 700 /home/$username/.ssh
    echo "Please paste the user's private key below (in one line):"
    read ssh_key
    sudo echo "$ssh_key" >> /home/$username/.ssh/authorized_keys
    sudo chmod 600 /home/$username/.ssh/authorized_keys
    sudo chown -R $username:$username /home/$username/.ssh
    echo "Private key added for user $username."
}

# Function to install Apache
install_apache() {
    if [[ $(rpm -q httpd) ]]; then
        echo "Apache is already installed."
    else
        echo "Installing Apache..."
        sudo dnf install -y httpd
        sudo systemctl start httpd
        sudo systemctl enable httpd
        echo "Apache installed and started."
    fi
}

# Function to install PostgreSQL
install_postgresql() {
    echo "Installing PostgreSQL..."
    if rpm -q postgresql-server >/dev/null 2>&1; then
        echo "PostgreSQL is already installed."
    else
        sudo dnf install -y postgresql-server postgresql-contrib
        sudo postgresql-setup --initdb
        sudo systemctl start postgresql
        sudo systemctl enable postgresql
        echo "PostgreSQL installed and started."
    fi
}

# Function to install Zabbix agent
install_zabbix_agent() {
    echo "Installing Zabbix agent..."
    if rpm -q zabbix-agent >/dev/null 2>&1; then
        echo "Zabbix agent is already installed."
    else
        sudo dnf install -y zabbix-agent
        sudo systemctl start zabbix-agent
        sudo systemctl enable zabbix-agent
        echo "Zabbix agent installed and started."
    fi
}

# Function to install figlet Docker image with alias figlet
install_figlet() {
    echo "Running figlet Docker image..."
    sudo alias figlet='docker run -i --rm mwendler/figlet'
    echo "figlet Docker image installed with alias figlet."
}

# Function to set firewall rules for http and https
set_firewall() {
    echo "Setting Firewall Rules..."
    if sudo firewall-cmd --zone=public --list-ports | grep -q "80/tcp"; then
        echo "Port 80/tcp is already open."
    else
        sudo firewall-cmd --zone=public --permanent --add-port=80/tcp
        echo "Port 80/tcp opened."
    fi
    if sudo firewall-cmd --zone=public --list-ports | grep -q "443/tcp"; then
        echo "Port 443/tcp is already open."
    else
        sudo firewall-cmd --zone=public --permanent --add-port=443/tcp
        echo "Port 443/tcp opened."
    fi
    sudo firewall-cmd --reload
    echo "Firewall rules set for ports 80/tcp and 443/tcp."
}

# Function to install Git
install_git() {
    echo "Installing Git..."
    if rpm -q git >/dev/null 2>&1; then
        echo "Git is already installed."
    else
        sudo dnf install git -y
        echo "Git has been installed."
    fi
}

# Main loop
while true; do
    # Show menu using whiptail
    option=$(whiptail --clear --title "Server Configuration Menu" --menu "Please select an option:" 15 60 7 \
    "1" "Install SSH" \
    "2" "Add sudo user" \
    "3" "Add SFTP user" \
    "4" "Install Docker and Docker Compose" \
    "5" "Disable SELinux" \
    "6" "Check installed version of Docker" \
    "7" "Uninstall Docker and Docker Compose" \
    "8" "Install Portainer" \
    "9" "Add user's private key for SSH" \
    "10" "Install Apache" \
    "11" "Install PostgreSQL" \
    "12" "Install Zabbix agent" \
    "13" "Install figlet Docker" \
    "14" "Set Firewall Rules For Apache 80/443" \
    "15" "Install Git" \
    "0" "Exit" 3>&1 1>&2 2>&3)

    # Check if user selected cancel or pressed the escape key
    if [[ $? -ne 0 ]]; then
        exit
    fi

    # Call appropriate function based on user input
    while true; do
        option=$(whiptail --title "Server Configuration" --menu "Choose an option" 15 50 8 \
            "1" "Install SSH" \
            "2" "Add sudo user" \
            "3" "Add SFTP user" \
            "4" "Install Docker and Docker Compose" \
            "5" "Disable SELinux" \
            "6" "Check installed version of Docker" \
            "7" "Uninstall Docker and Docker Compose" \
            "8" "Install Portainer" \
            "9" "Add user's private key for SSH" \
            "10" "Install Apache" \
            "11" "Install PostgreSQL" \
            "12" "Install Zabbix agent" \
            "13" "Install Figlet Docker" \
            "14" "Set Firewall Rules For Apache 80/443" \
            "15" "Install Git" \
            "0" "Exit" 3>&1 1>&2 2>&3)
        case $option in
            1) install_ssh;;
            2) add_sudo_user;;
            3) add_sftp_user;;
            4) install_docker;;
            5) disable_selinux;;
            6) check_docker_version;;
            7) uninstall_docker;;
            8) install_portainer;;
            9) add_ssh_key;;
            10) install_apache;;
            11) install_postgresql;;
            12) install_zabbix_agent;;
            13) install_figlet;;
            14) set_firewall;;
            15) install_git;;
            0) exit;;
            *) whiptail --title "Invalid option" --msgbox "Please choose a valid option." 8 50;;
        esac
    done
done
