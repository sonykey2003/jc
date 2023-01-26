$VNetName  = "VNet1"
$FESubName = "FrontEnd"
$BESubName = "Backend"
$GWSubName = "GatewaySubnet"
$VNetPrefix1 = "10.1.0.0/16"
$VNetPrefix2 = "10.254.0.0/16"
$FESubPrefix = "10.1.0.0/24"
$BESubPrefix = "10.254.1.0/24"
$GWSubPrefix = "10.1.255.0/27"
$VPNClientAddressPool = "172.16.201.0/24"
$RG = "TestRG1"
$Location = "Southeast Asia"
$GWName = "VNet1GW"
$GWIPName = "VNet1GWPIP"
$GWIPconfName = "gwipconf1"


New-AzResourceGroup -Name $RG -Location $Location

$fesub = New-AzVirtualNetworkSubnetConfig -Name $FESubName -AddressPrefix $FESubPrefix   
$besub = New-AzVirtualNetworkSubnetConfig -Name $BESubName  -AddressPrefix $BESubPrefix
$gwsub = New-AzVirtualNetworkSubnetConfig -Name $GWSubName  -AddressPrefix $GWSubPrefix

New-AzVirtualNetwork -Name $VNetName -ResourceGroupName $RG -Location $Location `
 -AddressPrefix $VNetPrefix1 ,$VNetPrefix2 `
 -Subnet $fesub, $besub, $gwsub -DnsServer 10.2.1.3


$vnet = Get-AzVirtualNetwork -Name $VNetName -ResourceGroupName $RG  
$subnet = Get-AzVirtualNetworkSubnetConfig -Name $GWSubName  -VirtualNetwork $vnet 
$pip = New-AzPublicIpAddress -Name $GWIPName  -ResourceGroupName $RG -Location $Location -AllocationMethod Dynamic 
$ipconf = New-AzVirtualNetworkGatewayIpConfig -Name $GWIPconfName -Subnet $subnet -PublicIpAddress $pip


New-AzVirtualNetworkGateway -Name $GWName -ResourceGroupName $RG `
-Location $Location -IpConfigurations $ipconf -GatewayType Vpn `
-VpnType RouteBased -EnableBgp $false -GatewaySku VpnGw1

$Secure_Secret=Read-Host -AsSecureString -Prompt "RadiusSecret"

$Gateway = Get-AzVirtualNetworkGateway -ResourceGroupName $RG -Name $GWName
Set-AzVirtualNetworkGateway -VirtualNetworkGateway $Gateway -VpnClientRootCertificates @()
Set-AzVirtualNetworkGateway -VirtualNetworkGateway $Gateway `
-VpnClientAddressPool "172.16.201.0/24" -VpnClientProtocol "OpenVPN" `
-RadiusServerAddress "158.140.128.223" -RadiusServerSecret $Secure_Secret