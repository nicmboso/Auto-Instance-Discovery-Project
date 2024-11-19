#!/bin/bash
set -x 

#defining our variables
AWSCLI_PATH='/usr/local/bin/aws'
INVENTORY_FILE='/etc/ansible/prod_hosts'
IPS_FILE='/etc/ansible/prod.lists'
ASG_NAME='pet-adoption-prod-asg'
SSH_KEY_PATH='~/.ssh/id_rsa'
WAIT_TIME=20

#write our functions
#fetching the IPs
find_ips() {
    \$AWSCLI_PATH ec2 describe-instances \\
    --filters "Name=tag:aws:autoscaling:groupName,Values=\$ASG_NAME" \\
    --query 'Reservations[*].Instances[*].NetworkInterfaces[*].PrivateIpAddress' \\
    --output text > "\$IPS_FILE"
}
#update the inventory files
update_inventory() {
    echo "[webservers]" > "\$INVENTORY_FILE" 
    while IFS= read -r instance; do
        ssh-keyscan -H "\$instance" >> ~/.ssh/known_hosts
        echo "\$instance ansible_user=ec2-user" >> "\$INVENTORY_FILE"
    done < "\$IPS_FILE"
    echo "Inventory updated succesfully"
}
#wait for some minutes
wait_for_seconds() {
    echo "Waiting for \$WAIT_TIME seconds..."
    sleep "\$WAIT_TIME"
}
# Function to check and start Docker container if not running
check_docker_container() {
    while read -r ip; do
        # Check if container is running
        ssh -i "\$SSH_KEY_PATH" ec2-user@"\$ip" "docker ps --filter 'name=appContainer' --format '{{.Names}}'" | grep -q "appContainer"
        if [[ $? -ne 0 ]]; then
            # Container not running, execute script to start container
            ssh -i "\$SSH_KEY_PATH" ec2-user@"\$ip" "/home/ec2-user/scripts/script.sh"
        fi
    done < "\$IPS_FILE"
}
# Main function block
main() {
    find_ips
    update_inventory
    wait_for_seconds
    check_docker_container
}
# Execute main function
main
