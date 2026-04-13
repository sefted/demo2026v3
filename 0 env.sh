# Example env.sh
export TIMEZONE="Asia/Tomsk"
export USER_ADMIN="admin"
export USER_SSH="sshuser"
export PASS="YourSecurePassword123"

# Network interfaces (replace with actual names, e.g., eth0, ens18, etc.)
export ISP_IF_WAN="ens192"
export ISP_IF_BR="ens256"
export ISP_IF_HQ="ens224"

export HQ_IF_WAN="ens192"
export HQ_IF_LAN="ens224"

export BR_IF_WAN="ens192"
export BR_IF_LAN="ens224"

export HQ_SRV_IF="ens224"
export BR_SRV_IF="ens224"
export HQ_CLI_IF="ens256"
