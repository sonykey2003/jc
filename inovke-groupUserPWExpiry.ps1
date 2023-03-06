#option 1 lockout accounts
Get-JCUserGroupMember -GroupName "demo-users" | Set-JCUser -account_locked:$true | select username,email,account_locked,created 


$users = Get-JCUserGroupMember -GroupName "demo-users"  
foreach ($u in $users){
    Invoke-JcSdkExpireUserPassword -id $u.userid -ErrorAction SilentlyContinue
    Get-jcUser -id $u.userid | select username,email,password_expired,password_expiration_date,password_date |ft
}
