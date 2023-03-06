# https://support.jumpcloud.com/s/article/re-enable-a-disabled-user-account-on-macos1-2019-08-21-10-36-47
# run this in sudo mode by running sudo -i 

for user in $(dscl . list /Users| grep -v '_'); do
    printf "%s: " "$user"
    dscl . -read /Users/$user AuthenticationAuthority &>/dev/null && (
        dscl . -read /Users/$user AuthenticationAuthority | grep -q ';DisabledUser;' && echo "Disabled" || echo "Enabled"
    ) || echo "N/A"
done