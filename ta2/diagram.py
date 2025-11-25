from diagrams import Cluster, Diagram, Edge
from diagrams.gcp.compute import KubernetesEngine
from diagrams.gcp.security import IAP
from diagrams.gcp.network import LoadBalancing, DNS, VPC, CDN
from diagrams.gcp.database import SQL
from diagrams.gcp.devtools import Build
from diagrams.gcp.devtools import ContainerRegistry
from diagrams.generic.device import Mobile
from diagrams.onprem.vcs import Git
from diagrams.k8s.compute import Deployment

graph_attr = {
    "fontsize": "20",
    "bgcolor": "white",
    "pad": "0.5",
    "splines": "spline",
    "rankdir": "TB",
    "ranksep": "0.8",
    "nodesep": "0.5"
}

with Diagram("Innovate Inc. GKE GitOps Architecture", show=False, graph_attr=graph_attr):

    # 1. External Sources
    Users = Mobile("End Users")
    AppCodeRepo = Git("Application Code Repo (Source)")
    ConfigRepo = Git("Kubernetes Config Repo (Desired State)")

    # 2. CI/CD Pipeline
    with Cluster("1. Continuous Integration (CI)"):
        BuildService = Build("Cloud Build\n(Build, Test, Push)")
        Registry = ContainerRegistry("Artifact Registry\n(Images)")

        # CI Flow: Code -> Build -> Registry
        AppCodeRepo >> BuildService >> Registry

    # 3. Production Environment (CD & Runtime)
    with Cluster("2. innovate-prod Project (GCP)"):

        # Public Layer / Traffic Entry
        with Cluster("Public Ingress"):
            DNS_Zone = DNS("Cloud DNS")
            CDN_Service = CDN("Cloud CDN")
            LoadBalancer = LoadBalancing("Global HTTP(S) Load Balancer")

            DNS_Zone >> CDN_Service >> LoadBalancer

        # Private Compute & Data Layer
        with Cluster("Virtual Private Cloud (VPC)"):

            # Compute Layer (GKE)
            with Cluster("Private Subnets (GKE Autopilot)"):
                GKE = KubernetesEngine("GKE Autopilot Cluster")
                ArgoController = Deployment("ArgoCD Controller (In-Cluster)")

                # Application Workloads
                with Cluster("Application Pods"):
                    Frontend = Deployment("SPA Frontend\n(React)")
                    Backend = Deployment("API Backend\n(Flask)")

                    # Internal traffic
                    Frontend >> Edge(label="Internal REST Calls") >> Backend

            # Database Layer
            with Cluster("Database Layer (Managed)"):
                DB = SQL("Cloud SQL\n(PostgreSQL, HA)")

    # External User Traffic Flow
    Users >> DNS_Zone

    # Deployment Flow (GitOps Pull)
    ConfigRepo >> Edge(label="Pulls Desired State") >> ArgoController
    Registry >> Edge(style="dashed", label="Image Tag Update") >> ConfigRepo
    ArgoController >> Edge(label="Applies Manifests") >> GKE

    # Runtime Traffic & Data Flow
    LoadBalancer >> Frontend
    Backend >> Edge(label="Private DB Connection") >> DB

    # Secure Admin Access
    AdminAccess = IAP("IAP/Cloud Shell (Admin)")
    AdminAccess >> GKE
