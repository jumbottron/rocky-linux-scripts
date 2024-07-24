#!/bin/bash
# Check if zenity is installed
if ! command -v zenity &> /dev/null; then
    echo "zenity is not installed. Installing it now..."
    sudo dnf install zenity -y
fi
# Function to display the menu
show_menu() {
    selection=$(zenity --width=600 --height=500 --list \
        --title="System Configuration Menu" \
        --text="Please select an option:" \
        --column="Option" --column="Description" \
        "Install SSH" "Install SSH and start the service" \
        "Add sudo user" "Add a new user with sudo privileges" \
        "Add SFTP user" "Add a new user with SFTP access" \
        "Install Docker and Docker Compose" "Install Docker and Docker Compose" \
        "Disable SELinux" "Disable SELinux" \
        "Check installed version of Docker" "Check the installed version of Docker" \
        "Uninstall Docker and Docker Compose" "Uninstall Docker and Docker Compose" \
        "Install Portainer" "Install Portainer management UI for Docker" \
        "Add user's private key for SSH" "Add a user's private key for SSH access" \
        "Install Apache" "Install Apache web server" \
        "Install PostgreSQL" "Install PostgreSQL database server" \
        "Install Zabbix agent" "Install Zabbix agent monitoring software" \
        "Install Figlet Docker" "Install the Figlet Docker image with alias figlet" \
        "Set Firewall Rules For Apache 80/443" "Set firewall rules for Apache ports 80/tcp and 443/tcp" \
        "Install Git" "Install Git version control system" \
        "Exit" "Exit the script")

    case $selection in
        "Install SSH")
            install_ssh
            ;;
        "Add sudo user")
            add_sudo_user
            ;;
        "Add SFTP user")
            add_sftp_user
            ;;
        "Install Docker and Docker Compose")
            install_docker
            ;;
        "Disable SELinux")
            disable_selinux
            ;;
        "Check installed version of Docker")
            check_docker_version
            ;;
        "Uninstall Docker and Docker Compose")
            uninstall_docker
            ;;
        "Install Portainer")
            install_portainer
            ;;
        "Add user's private key for SSH")
            add_ssh_key
            ;;
        "Install Apache")
            install_apache
            ;;
        "Install PostgreSQL")
            install_postgresql
            ;;
        "Install Zabbix agent")
            install_zabbix_agent
            ;;
        "Install Figlet Docker")
            install_figlet
            ;;
        "Set Firewall Rules For Apache 80/443")
            set_firewall
            ;;
        "Install Git")
            install_git
            ;;
        "Exit")
            exit 0
            ;;
        *)
            show_menu
            ;;
    esac
}

#!/bin/bash

# Function to install SSH
install_ssh() {
    if [[ $(rpm -q openssh-server) ]]; then
        zenity --info --text="SSH is already installed."
    else
        zenity --info --text="Installing SSH..."
        sudo dnf install -y openssh-server
        sudo systemctl start sshd
        sudo systemctl enable sshd
        zenity --info --text="SSH installed and started."
    fi
}

# Function to add sudo user
add_sudo_user() {
    username=$(zenity --entry --title="Add Sudo User" --text="Please enter the username for the new sudo user:")
    if [ $? -eq 0 ]; then
        if [[ $(sudo -lU $username | grep -c "(ALL : ALL)") -ne 0 ]]; then
            zenity --info --text="User $username is already a sudoer."
        else
            sudo useradd -m -s /bin/bash $username
            sudo passwd $username
            sudo usermod -aG wheel $username
            zenity --info --text="User $username added to sudo group."
        fi
    else
        zenity --info --text="User creation cancelled."
    fi
}

# Function to add SFTP user
add_sftp_user() {
    username=$(zenity --entry --title="Add SFTP User" --text="Please enter the username for the new SFTP user:")
    if [ $? -eq 0 ]; then
        if [[ $(id -nG $username | grep -c sftp) -ne 0 ]]; then
            zenity --info --text="User $username is already an SFTP user."
        else
            sudo useradd -m -s /bin/false $username
            sudo passwd $username
            sudo usermod -aG sftp $username
            sudo chown root:root /home/$username
            sudo chmod 755 /home/$username
            sudo mkdir /home/$username/files
            sudo chown $username:$username /home/$username/files
            zenity --info --text="User $username added for SFTP."
        fi
    else
        zenity --info --text="User creation cancelled."
    fi
}

# Function to install Docker and Docker Compose
install_docker() {
    zenity --info --text="Installing Docker and Docker Compose..."
    if rpm -q docker-ce docker-ce-cli containerd.io docker-compose >/dev/null 2>&1; then
        zenity --info --text="Docker and Docker Compose are already installed."
    else
        sudo dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
        sudo dnf install -y docker-ce docker-ce-cli containerd.io
        sudo systemctl start docker
        sudo systemctl enable docker
        sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        zenity --info --text="Docker and Docker Compose installed and started."
    fi
}

# Function to disable SELinux
disable_selinux() {
    if [[ $(sestatus | grep -c "SELinux status: enabled") -ne 0 ]]; then
        zenity --info --text="Disabling SELinux..."
        sudo sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
        zenity --info --text="SELinux disabled. Please restart the system."
    else
        zenity --info --text="SELinux is already disabled."
    fi
}

# Function to check the installed version of Docker
check_docker_version() {
    if [[ $(rpm -q docker-ce) ]]; then
        docker_version=$(rpm -q docker-ce --queryformat '%{VERSION}')
        zenity --info --text="Docker version $docker_version is installed."
    else
        zenity --info --text="Docker is not installed."
    fi
}

# Function to uninstall Docker and Docker Compose
uninstall_docker() {
    zenity --question --text="This will remove Docker and Docker Compose. Are you sure you want to continue?"
    if [ $? -eq 0 ]; then
        zenity --info --text="Uninstalling Docker and Docker Compose..."
        sudo dnf remove -y docker-ce docker-ce-cli containerd.io docker-compose
        sudo rm -f /usr/local/bin/docker-compose
        zenity --info --text="Docker and Docker Compose uninstalled."
    else
        zenity --info --text="Uninstall cancelled."
    fi
}

# Function to install Portainer management UI for Docker
install_portainer() {
    zenity --info --text="Installing Portainer..."
    if [[ $(docker ps -a --format '{{.Names}}' | grep -c portainer) -ne 0 ]]; then
        zenity --info --text="Portainer is already installed."
    else
        sudo docker volume create portainer_data
        sudo docker run -d -p 9000:9000 --name portainer --restart always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce
        zenity --info --text="Portainer installed and started."
    fi
}

# Function to add a user's private key for SSH access
add_ssh_key() {
    username=$(zenity --entry --title="Add SSH Key" --text="Please enter the username of the user:")
    if [ $? -eq 0 ]; then
        ssh_dir="/home/$username/.ssh"
        if [[ ! -d $ssh_dir ]]; then
            sudo mkdir $ssh_dir
            sudo chown $username:$username $ssh_dir
            sudo chmod 700 $ssh_dir
        fi
        ssh_file="$ssh_dir/authorized_keys"
        if [[ -f $ssh_file ]]; then
            zenity --info --text="File $ssh_file already exists. Appending to file..."
        else
            sudo touch $ssh_file
            sudo chown $username:$username $ssh_file
            sudo chmod 600 $ssh_file
        fi
        ssh_key=$(zenity --file-selection --title="Add SSH Key" --text="Please select the SSH key file:")
        if [ $? -eq 0 ]; then
            cat $ssh_key | sudo tee -a $ssh_file >/dev/null
            zenity --info --text="SSH key added for user $username."
        else
            zenity --info --text="SSH key addition cancelled."
        fi
    else
        zenity --info --text="SSH key addition cancelled."
    fi
}

# Function to install Apache web server
install_apache() {
    zenity --info --text="Installing Apache..."
    if [[ $(rpm -q httpd) ]]; then
        zenity --info --text="Apache is already installed."
    else
        sudo dnf install -y httpd
        sudo systemctl start httpd
        sudo systemctl enable httpd
        zenity --info --text="Apache installed and started."
    fi
}

# Function to install PostgreSQL database server
install_postgresql() {
    zenity --info --text="Installing PostgreSQL..."
    if [[ $(rpm -q postgresql-server) ]]; then
        zenity --info --text="PostgreSQL is already installed."
    else
        sudo dnf install -y postgresql-server
        sudo systemctl initdb
        sudo systemctl start postgresql
        sudo systemctl enable postgresql
        zenity --info --text="PostgreSQL installed and started."
    fi
}

# Function to install Zabbix agent monitoring software
install_zabbix_agent() {
    zenity --info --text="Installing Zabbix agent..."
    if [[ $(rpm -q zabbix-agent) ]]; then
        zenity --info --text="Zabbix agent is already installed."
    else
        sudo dnf install -y zabbix-agent
        sudo systemctl start zabbix-agent
        sudo systemctl enable zabbix-agent
        zenity --info --text="Zabbix agent installed and started."
    fi
}

# Function to install the Figlet Docker image with alias figlet
install_figlet() {
    zenity --info --text="Installing Figlet Docker image..."
    if [[ $(sudo docker images | grep -c figlet) -ne 0 ]]; then
        zenity --info --text="Figlet Docker image already installed."
    else
        sudo docker run --name figlet -d tutum/figlet
        zenity --info --text="Figlet Docker image installed."
    fi
}

# Function to set firewall rules for Apache ports 80/tcp and 443/tcp
set_firewall() {
    zenity --info --text="Setting firewall rules for Apache..."
    sudo firewall-cmd --add-service={http,https} --permanent
    sudo firewall-cmd --reload
    zenity --info --text="Firewall rules for Apache set."
}

# Function to install Git version control system
install_git() {
    zenity --info --text="Installing Git..."
    if [[ $(rpm -q git) ]]; then
        zenity --info --text="Git is already installed."
    else
        sudo dnf install -y git
        zenity --info --text="Git installed."
    fi
}

# Main program
show_menu
