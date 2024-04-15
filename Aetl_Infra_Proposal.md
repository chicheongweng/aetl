# Aetl Infrastructure Proposal (Transitioning to a Linux/.NET/Azure SQL Stack hosted on Azure)

The assignment called for an Azure infrastructure proposal for hosting a LAMP stack application. However, as we're developing a client-facing application for a prestigious organization like Aetl, it's paramount that we employ the most sophisticated and scalable technology stack offered by Microsoft Azure. To this end, I propose a transition from the LAMP (Linux/Apache/MySQL/PHP) stack to a Linux/.NET/Azure SQL stack. This shift will ensure we're harnessing the most resilient technologies to meet the ever-increasing demands.

## Leverage Azure Blueprints to Ensure Governance from Day 1

Azure Blueprints is a service that enables us to define a repeatable set of Azure resources that adhere to certain requirements and standards.

With Azure Blueprints, we can create environments with a set of compliant resources — such as app services, network configurations, and policies — that can be used over and over again. This not only ensures that our environments are set up correctly from the start, but also saves time and reduces the possibility of errors.

Azure Blueprints also provides versioning and auditing features. This means we can track changes to our environments over time and ensure that they continue to comply with our requirements and standards.

By using Azure Blueprints in our architecture, we can ensure that our Azure resources are consistently set up and governed from day one. This can result in a more secure, compliant, and manageable cloud environment.

## Highly Available and Secure Multi-tier Architecture Design

**Web Tier - Azure App Service (Linux) and CDN in conjunction with Azure Blob Storage in conjunction:** I propose we use Azure App Service to handle business logic and restful API calls that return JSON data, and CDN in conjunction with Azure blob storage to serve static web artifacts such as css, image and video files. Azure App Service is a fully managed platform designed for the development, deployment, and scaling of web applications. It supports .NET Core, a versatile framework for creating modern, cloud-based web applications. Azure App Service allows us to concentrate on our application code, while Azure manages the infrastructure. It offers automatic scaling, CI/CD integration, custom domains, SSL, among other features. Using CDN in conjunction with Azure Blob Storage to serve static web artifacts will make serving static objects more cost-effective and more scalable.

By adopting .NET Core, we can utilize the contemporary language features of C#, such as strong typing and asynchronous programming. .NET Core is renowned for its high performance, often surpassing traditional PHP applications in benchmarks. While PHP has made significant improvements over the years, it may not offer the same level of performance or modern language features as .NET Core. It's also worth noting that, like any language, PHP requires careful coding and maintenance practices to ensure application security. With Azure App Service deployment slots feature, we can also achieve minimum deployment downtime by leveraging hot swap.

To streamline access control, we can use Azure Active Directory (Azure AD) to authenticate and authorize users to the application hosted on Azure App Service. This can be done by configuring App Service Authentication / Authorization.

**Data Tier - Azure SQL Database:** I propose we use Azure SQL with Geo-Redundancy enabled to protect against regional outages and Transparent Data Encryption (TDE) enabled for encryption at rest. Azure SQL Database is a fully managed relational database service that features built-in intelligence that learns our unique database patterns and provides personalized recommendations to optimize our database performance. It manages all the database functions like upgrading, patching, backups, and monitoring without user involvement.

Transitioning from MySQL to Azure SQL Database allows us to utilize advanced features like automatic tuning, threat detection, and Azure Active Directory integration. Azure SQL Database also offers seamless integration with other Azure services, simplifying the creation of comprehensive solutions. It will also allow us to better leverage Microsoft's A.I.

We can set up Azure AD authentication to allow only authorized users to access the databases.

**Caching Layer - Azure Redis Cache:** To further enhance the performance of our application, I propose integrating Azure Redis Cache. This will allow us to cache frequently accessed data, reducing the load on our Azure SQL Database and improving response times. It can also be used for session state caching if our application has a lot of user sessions. In addition, Redis supports data structures that can be used for real-time analytics.

**Security:** I propose we use Azure Security Center for unified security management and advanced threat (e.g. DDoS attacks) protection across our hybrid cloud workloads; Azure Disk Encryption and Azure Storage Service Encryption for safeguarding our data at rest; and Azure Application Gateway as a web application firewall against common web-based threats. I also propose we use Azure Key Vault to store database and other confidential credentials.

**Backup and Monitoring:** I propose we use Azure Backup to back up our Azure SQL Databases, and Azure Monitor to enhance the availability and performance of our applications. Azure Monitor offers a comprehensive solution to collect, analyze, and act on telemetry data from your Azure and on-premises environments. It helps us understand how the applications are performing and proactively identifies issues affecting them and the resources they depend on. We can also use Azure Monitor to set up alerts so administrators will be notified in real-time of any issues via e-mail and sms.

We can use Azure AD to control access to monitoring data.

**Private Network Connectivity for Communication Between the Application and On-Premises Backend Systems:** I propose we use Azure ExpressRoute. Azure ExpressRoute is a service that enables us to create private connections between Azure data centers and infrastructure on our premises or in a co-location environment. ExpressRoute connections do not go over the public Internet, offering more reliability, faster speeds, lower latitudes, and higher security than typical connections over the Internet.

This service allows us to extend our on-premises networks into the Microsoft cloud over a private connection facilitated by a connectivity provider. With ExpressRoute, we can establish connections to Microsoft cloud services, such as Microsoft Azure and Microsoft 365. 

This private network connectivity is crucial for secure and reliable communication between the application and backend systems, ensuring data integrity and performance.

**Enhanced Security with Private Endpoints:** To further enhance the security of our application, we can leverage Azure Private Endpoints. Private Endpoints provide secure and direct connectivity to Azure services over a private IP address in our Virtual Network (VNet). This ensures that the traffic between our VNet and the Azure service travels over the Microsoft backbone network, eliminating exposure from the public internet. This not only enhances security but also simplifies the network configuration by keeping access rules to a minimum.

**Environment Separation:** I propose we use Azure Subscriptions to provide natural boundaries for separating environments. This can assist with cost tracking, management delegation, and access control.

By adopting this architecture, we can harness the power and flexibility of Azure, while also benefiting from the performance and modern features of .NET and MS SQL. This transition can result in a more robust, scalable, and maintainable application.

## Leveraging Azure Traffic Manager for Increased Robustness

Azure Traffic Manager is a DNS-based traffic load balancer that enables us to distribute traffic optimally to services across global Azure regions, while providing high availability and responsiveness. By leveraging Traffic Manager, we can increase the robustness of our overall system in several ways:

**Global Load Balancing:** Traffic Manager uses DNS to direct client requests to the most appropriate service endpoint based on a traffic-routing method and the health of the endpoints. This can help improve the distribution of traffic for services running in different regions, ensuring that no single region becomes a bottleneck.

**Automatic Failover:** Traffic Manager continuously monitors the health of our endpoints. If a failure is detected, Traffic Manager automatically directs traffic away from the failed endpoint and towards the next best endpoint. This ensures that our application remains available even in the event of a regional outage.

**Performance Optimization:** Traffic Manager can direct traffic to the endpoint with the lowest network latency for the client making the request. This can help improve the performance of our applications, leading to a better user experience.

By integrating Azure Traffic Manager into our architecture, we can ensure that our application remains highly available and responsive, even in the face of regional outages or uneven traffic distribution.

## Assumptions:

- The application requirements can be full-filled with .NET Core and can be hosted on Azure App Service.
- The database can be migrated from MySQL to Azure SQL Database.
- The on-premises backend systems can communicate over Azure Private Link.
- The organization has the necessary Azure subscriptions and permissions to create and manage these resources.

## Implementation

The `provision-landing-zone.sh` (https://github.com/chicheongweng/aetl/blob/master/provision-landing-zone.sh) script provisions a set of Azure resources and services for DEV, UAT, and PROD environments for a project, following best practice naming convention. It takes DEV, UAT, or PROD as a command line argument. All resources and services are created in a resource group under one VNet, with each service in its own subnet and nsg. The SKUs are chosen to ensure zone redundancy and high availability where needed. The landing zone provisioned with this script is very easy to extend. 

Here's a detailed breakdown of the key components it creates:

- **Resource Group**: A logical container for resources deployed on Azure. All the resources created by the script are placed in this resource group.

- **Virtual Network (VNet)**: The fundamental building block for a private network in Azure. It provides isolation and segmentation, route control, and filters traffic.

- **Key Vault**: A service that stores and manages cryptographic keys and secrets in Azure. These can be used to encrypt data and authenticate applications.

- **Storage Account**: Provides scalable and secure storage for data objects in Azure. It can store files, blobs, queues, tables, and disks.

- **Log Analytics Workspace**: A unique environment for Azure Monitor log data. Each workspace has its own data repository and configuration, and data sources and solutions are configured to store their data in a workspace.

- **Private DNS Zone**: Provides name resolution for Virtual Network resources within a specific domain.

- **Jumpbox**: A secure computer that all admins first connect to before launching any administrative task or use as an origination point to connect to other servers or untrusted environments.

- **Azure SQL Database**: A fully managed relational database with auto-scale, integral intelligence, and robust security.

- **Private Endpoint**: A network interface that connects us privately and securely to a service powered by Azure Private Link.

- **App Service Plan**: Defines a set of compute resources for a web app to run. These compute resources are analogous to the server farm in conventional web hosting. The SKU chosen for the App Service Plan ensures high availability and zone redundancy.

- **App Service**: A fully managed platform for building, deploying, and scaling our web apps. The Docker image used by the App Service is specified in the script.

- **Application Gateway**: A web traffic load balancer that enables us to manage traffic to our web applications. The SKU chosen for the Application Gateway ensures high availability and zone redundancy.

- **Inbound and Outbound Subnets**: Segments of the VNet IP address range where we can assign resources. The script creates two subnets for the App Service, one for inbound traffic and one for outbound traffic.

- **Managed Identity and Service Principal**: The App Service will access the key vault with its managed identity. We will also create a service principal for Azure DevOps to deploy images to App Service. 

Each of these components is created with specific configurations, such as names, locations, and sizes, which are defined by the parameters at the beginning of the script. The script also includes parameters for SSL certificates and the Docker image to be used by the App Service.

# Architecture Diagram:

![Aetl Infrastructure Diagram](https://github.com/chicheongweng/aetl/blob/master/Aetl_Infra_Diagram.jpg)

# Screenshots of Azure portal after deployment:

![Screenshot 1](https://github.com/chicheongweng/aetl/blob/master/screenshot1.png)

![Screenshot 2](https://github.com/chicheongweng/aetl/blob/master/screenshot2.png)
