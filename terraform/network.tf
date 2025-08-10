resource "random_pet" "lb_hostname" {
}

# Create an virtual network and subnet
resource "azurerm_virtual_network" "deploy" {
  name                = "terraformvnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.deploy.location
  resource_group_name = azurerm_resource_group.deploy.name
}

resource "azurerm_subnet" "deploy" {
  name                 = "deploy-subnet"
  resource_group_name  = azurerm_resource_group.deploy.name
  virtual_network_name = azurerm_virtual_network.deploy.name
  address_prefixes     = ["10.0.1.0/24"]
  
}

resource "azurerm_subnet" "dns_inbound" {
  name                 = "dns-inbound"
  resource_group_name  = azurerm_resource_group.deploy.name
  virtual_network_name = azurerm_virtual_network.deploy.name
  address_prefixes     = ["10.0.10.0/27"]
  delegation {
     name = "dnsresolverdelegation"

     service_delegation {
      name    = "Microsoft.Network/dnsResolvers"
      actions = [
      "Microsoft.Network/virtualNetworks/subnets/join/action",
      "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
      "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
      ]
    }
  } 
}

resource "azurerm_subnet" "dns_outbound" {
  name                 = "dns-outbound"
  resource_group_name  = azurerm_resource_group.deploy.name
  virtual_network_name = azurerm_virtual_network.deploy.name
  address_prefixes     = ["10.0.11.0/27"]
  delegation {
     name = "dnsresolverdelegation"

     service_delegation {
      name    = "Microsoft.Network/dnsResolvers"
      actions = [
      "Microsoft.Network/virtualNetworks/subnets/join/action",
      "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
      "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
      ]
    }
  } 
}

resource "azurerm_network_security_group" "deploy" {
  name                = "deploy-nsg"
  location            = azurerm_resource_group.deploy.location
  resource_group_name = azurerm_resource_group.deploy.name
}

resource "azurerm_subnet_network_security_group_association" "deploy" {
  subnet_id                 = azurerm_subnet.deploy.id
  network_security_group_id = azurerm_network_security_group.deploy.id
}

resource "azurerm_resource_group" "deploy" {
  name     = "aadds-rg"
  location = "westeurope"
}

resource "azurerm_subnet" "subnet" {
  name                 = "subnet"
  resource_group_name  = azurerm_resource_group.deploy.name
  virtual_network_name = azurerm_virtual_network.deploy.name
  address_prefixes     = ["10.0.2.0/24"]
  delegation {
     name = "dnsresolverdelegation"

     service_delegation {
      name    = "Microsoft.Network/dnsResolvers"
      actions = [
      "Microsoft.Network/virtualNetworks/subnets/join/action",
      "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
      "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
      ]
    }
  } 
  
}

module "private_resolver" {
  source = "git::https://github.com/jeemeekay/terraform-azurerm-avm-res-network-dnsresolver.git?ref=v0.0.4" # Replace source with the following line

  location                    = azurerm_resource_group.deploy.location
  name                        = "resolver"
  resource_group_name         = azurerm_resource_group.deploy.name
  virtual_network_resource_id = azurerm_virtual_network.deploy.id
  inbound_endpoints = {
    "inbound1" = {
      name        = "inbound1"
      subnet_name = azurerm_subnet.dns_inbound.name
      tags = {
        "source" = "onprem"
      }
      merge_with_module_tags = false
    }
  }
  outbound_endpoints = {
    "outbound1" = {
      name        = "outbound1"
      subnet_name = azurerm_subnet.dns_outbound.name
      tags = {
        "destination" = "onprem"
      }
      merge_with_module_tags = true
      forwarding_ruleset = {
        "ruleset1" = {
          tags = {
            "environment" = "test"
          }
          additional_outbound_endpoint_link = {
            outbound_endpoint_key = "outbound2" # a key referencing another outbound endpoint in this map
          }
          merge_with_module_tags = false
          name                   = "ruleset1"
          rules = {
            "rule1" = {
              name        = "rule1"
              domain_name = "${data.azuread_domains.default.domains.1.domain_name}."
              state       = "Enabled"
              destination_ip_addresses = {
                "10.0.11.3" = "53"
                "10.0.11.4" = "53"
              }
            }
          }
        }
      }
    }
    "outbound2" = {
      name        = "outbound2"
      subnet_name = azurerm_subnet.subnet.name
    }
  }
  tags = {
    "created_by" = "terraform"
  }
}


# network security group for the subnet with a rule to allow http, https and ssh traffic
resource "azurerm_network_security_group" "myNSG" {
  name                = "myNSG"
  location            = azurerm_resource_group.deploy.location
  resource_group_name = azurerm_resource_group.deploy.name

  security_rule {
    name                       = "allow-http"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-https"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  #ssh security rule
  security_rule {
    name                       = "allow-ssh"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "myNSG" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.myNSG.id
}

# A public IP address for the load balancer
resource "azurerm_public_ip" "of-deploy" {
  name                = "lb-publicIP"
  location            = azurerm_resource_group.deploy.location
  resource_group_name = azurerm_resource_group.deploy.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
  domain_name_label   = "${azurerm_resource_group.deploy.name}-${random_pet.lb_hostname.id}"
}

# A load balancer with a frontend IP configuration and a backend address pool
resource "azurerm_lb" "of-deploy" {
  name                = "myLB"
  location            = azurerm_resource_group.deploy.location
  resource_group_name = azurerm_resource_group.deploy.name
  sku                 = "Standard"
  frontend_ip_configuration {
    name                 = "myPublicIP"
    public_ip_address_id = azurerm_public_ip.of-deploy.id
  }
}

resource "azurerm_lb_backend_address_pool" "bepool" {
  name            = "myBackendAddressPool"
  loadbalancer_id = azurerm_lb.of-deploy.id
}

#set up load balancer rule from azurerm_lb.example frontend ip to azurerm_lb_backend_address_pool.bepool backend ip port 80 to port 80
resource "azurerm_lb_rule" "of-deploy" {
  name                           = "http"
  loadbalancer_id                = azurerm_lb.of-deploy.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "myPublicIP"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.bepool.id]
  probe_id                       = azurerm_lb_probe.of-deploy.id
}

#set up load balancer probe to check if the backend is up
resource "azurerm_lb_probe" "of-deploy" {
  name            = "http-probe"
  loadbalancer_id = azurerm_lb.of-deploy.id
  protocol        = "Http"
  port            = 80
  request_path    = "/"
}

#add lb nat rules to allow ssh access to the backend instances
resource "azurerm_lb_nat_rule" "ssh" {
  name                           = "ssh"
  resource_group_name            = azurerm_resource_group.deploy.name
  loadbalancer_id                = azurerm_lb.of-deploy.id
  protocol                       = "Tcp"
  frontend_port_start            = 50000
  frontend_port_end              = 50119
  backend_port                   = 22
  frontend_ip_configuration_name = "myPublicIP"
  backend_address_pool_id        = azurerm_lb_backend_address_pool.bepool.id
}

resource "azurerm_public_ip" "natgwpip" {
  name                = "natgw-publicIP"
  location            = azurerm_resource_group.deploy.location
  resource_group_name = azurerm_resource_group.deploy.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1"]
}

#add nat gateway to enable outbound traffic from the backend instances
resource "azurerm_nat_gateway" "of-deploy" {
  name                    = "nat-Gateway"
  location                = azurerm_resource_group.deploy.location
  resource_group_name     = azurerm_resource_group.deploy.name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
  zones                   = ["1"]
}

resource "azurerm_subnet_nat_gateway_association" "of-deploy" {
  subnet_id      = azurerm_subnet.subnet.id
  nat_gateway_id = azurerm_nat_gateway.of-deploy.id
}

# add nat gateway public ip association
resource "azurerm_nat_gateway_public_ip_association" "of-deploy" {
  public_ip_address_id = azurerm_public_ip.natgwpip.id
  nat_gateway_id       = azurerm_nat_gateway.of-deploy.id
}
