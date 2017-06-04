#!/bin/bash
WORKDIR=/<your_home_folder>
HOSTNAME="$2"
VM_DIR="$WORKDIR"/"$HOSTNAME"
ARGS="$#"
OS_TYPE="$1"
#function for choosing os distr
function check_distr() {
if [[ "$OS_TYPE" == "create" ]];then
    IMAGE=/<your_ubuntu_image>
    DISTR=ubuntu
else
    IMAGE=/<your_centos_image> 
    DISTR=centos
fi
}
#function for checking existence of needed files and dirs
function check_requirements() {
if [[ -d "$WORKDIR"  ]];then
    echo > /dev/null
else
    echo "$WORKDIR doesn't exist"
    exit 30
fi
if [[ -f "$IMAGE"  ]];then
    echo > /dev/null
else
    echo "$IMAGE doesn't exist"
    exit 30
fi
}
#function for checking cli args
function check_args() {
if [[ "$ARGS" != 2 ]];then
    echo "Usage :  `basename $0` <create> or <delete> <vm_name>"
fi
}
#function for checking vm existence
function check_vm() {
virsh list --all | grep -qw "$HOSTNAME"
}
#function for creating vm
function create_vm() {
check_args 
check_vm
if [[ "$?" != 0 ]];then
    echo > /dev/null
else
    echo  "VM $HOSTNAME already exists"
    exit 10
fi
mkdir "$VM_DIR"
pushd "$VM_DIR" &>/dev/null
if [[ "$DISTR" == "ubuntu" ]];then
    cat > user_data_"$HOSTNAME" << EOF
#cloud-config
users:
  - name: ubuntu
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    groups: sudo
    ssh-authorized-keys:
      - ssh-rsa <your_ssh_pub_key>
hostname: "$HOSTNAME"
manage_etc_hosts: true
EOF
else
    cat > user_data_"$HOSTNAME" << EOF
#cloud-config
user: ubuntu
shell: /bin/bash
sudo: ['ALL=(ALL) NOPASSWD:ALL']
groups: sudo
ssh_authorized_keys:
  - ssh-rsa <your_ssh_pub_key>
hostname: "$HOSTNAME"
preserver_hostname: true
manage_etc_hosts: true
EOF
fi
cp "$IMAGE" "$HOSTNAME".qcow2
cloud-localds init_"$HOSTNAME".img user_data_"$HOSTNAME" &> /dev/null
virt-install --import --name "$HOSTNAME" --ram 256 --vcpus 1 --disk \
    "$HOSTNAME".qcow2,format=qcow2,bus=virtio --disk init_"$HOSTNAME".img,device=cdrom --network \
    bridge=virbr0,model=virtio --noautoconsole
popd &>/dev/null
echo -ne "Waiting for VM ip\r"
sleep 7
echo -ne "Waiting for VM ip 20%\r"
sleep 7
echo -ne "Waiting for VM ip 40%\r"
sleep 7
echo -ne "Waiting for VM ip 60%\r"
sleep 7
echo -ne "Waiting for VM ip 80%\r"
sleep 10
echo 
ip_finder
}
#function for deleting vm
function delete_vm() {
check_args
check_vm
if [[ "$?" != 0 ]];then
    echo "No such VM"
    exit 20
fi
virsh destroy "$HOSTNAME"
virsh undefine "$HOSTNAME"
rm -rf "$VM_DIR"
echo "Domain $HOSTNAME was successfully deleted"
}
#function for list vm 
function list_vm() {
virsh list
}
check_distr
check_requirements
case "$1" in 
    args)
        check_args
        ;;
    create|create2)
        create_vm
        ;;
    delete)
        delete_vm
        ;;
    list)
        list_vm
	;;
    *)
        echo "Usage :  `basename $0` <create> or <delete> <vm_name>"
        echo "****************************************************"
        virsh list
	echo "****************************************************"
        ip_finder
        ;;
esac
