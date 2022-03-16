---
title: NIGNX proxy in Kubernetes for Sendgrid SSL click Tracking
author:
  name: Mate Hajnal
  link: https://github.com/hajnalmt
categories: [Blogging, CV, Writing]
tags: [sendgrid, ssltracking, ssl, clicktracking, kubernetes, ingress]
toc: false
pin: true
---

Before I get into the article I want to thank tg44 (Gergő Törcsvári) who created the final configuration, check [his blog](https://tg44.github.io/) too if you have some time.

Sendgrid is an e-mail delivery service which my company is using to send e-mails.
I won't dive into its features, because its a quite common service, with great features, and a reasonable price.

> To understand this post you need to be familiar with Kubernetes, at least you need to know the concept of Ingresses and Services.
{: .prompt-info }


### Intro

Last year we had a problem when we decieded to switch our Cluster from Rancher Cattle to Kubernetes.
The e-mails contained https links, which we wanted to track (How many of them got clicked on etc.), and Sendgrid has an inbuilt feature called SSL click tracking, with a nice [documentation](https://docs.sendgrid.com/ui/analytics-and-reporting/click-tracking-ssl).

### Basics

A normal click tracking can be set up with quite little knowledge, with an external domain (most of the cases), after the [domain authentication](https://docs.sendgrid.com/ui/account-and-settings/how-to-set-up-domain-authentication) and the [link branding](https://docs.sendgrid.com/ui/account-and-settings/how-to-set-up-link-branding) steps basically you are ready.

Although there are some [best pracices](https://docs.sendgrid.com/ui/analytics-and-reporting/click-tracking-html-best-practices) you are better to follow.

### SSL Click tracking

When we are speaking about SSL click tracking, we want to route the https links appropriately to the sendgrid server and than to us seemlessly. The than to us part is done by sendgrid itself, so we need to focus on the first one. The [documentation](https://docs.sendgrid.com/ui/analytics-and-reporting/click-tracking-ssl) says to use CDN to manage the certificates, which is intriguing at least, and you need to pay for these services.

The second paragraph says that the other way is to setup a [custom ssl configuration](https://docs.sendgrid.com/ui/account-and-settings/custom-ssl-configurations), so I started to dived into it.
So far when you set up the linkbranding you have already created the domain routing, with the CNAME domain entry setting: `urlxxxx.yourdoamin.com` to `sendgrid.net`.
This is the url you will need into the upcoming tutorial. The task itself is to prepare a proxy which receives all the inbound traffic and forwards it to http://sendgrid.net or https://sendgrid.net in our case, which means in Kubernetes terms, to setup an ingress with a backend service.

### Ingress and service

We use an [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/) with a cert-manager ClusterIssuer in our Kubernetes cluster, and most of the time this will be your case too, but to create an ingress we need to have a service first which it can point to, so we are starting with that.
This [stackoverflow post](https://stackoverflow.com/questions/64705450/redirecting-traffic-to-external-url) is really helpful to understand all of this.

The Service just needs to forward traffic to an external DNS (sendgrid.net). Kubernetes has a solution for it, we can define an [ExternalName](https://kubernetes.io/docs/concepts/services-networking/service/#externalname) type Service for this, which exactly does that.

So the Service will look like this.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: sendgrid-net
  namespace: sengrid-proxy
spec:
  type: ExternalName
  externalName: sendgrid.net
```

> You need to create the sendgrid-proxy namespace of course `kubectl create namespace sendgrid-proxy`, or edit the namespace part.
{: .prompt-info }

Now we are able to create the ingress. It will look like this:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    cert-manager.io/cluster-issuer: letsencypt-prod
    nginx.ingress.kubernetes.io/proxy-body-size: "0"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/upstream-vhost: "urlxxxx.yourdoamin.com"
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
    kubernetes.io/ingress.class: "nginx"
  name: sendgrid
  namespace: sengrid-proxy
spec:
  rules:
    - host: urlxxxx.yourdoamin.com
      http:
        paths:
          - backend:
              service:
                name: sendgrid-net
                port:
                  number: 443
            path: /
            pathType: ImplementationSpecific
  tls:
    - hosts:
        - urlxxxx.yourdoamin.com
      secretName: urlxxxx.yourdoamin.com
```

This ingress uses the letsencypt-prod cert-manager, which can of course differ in your cluster, but apart from that, you need to edit the `urlxxxx.yourdoamin.com` lines only.

Regarding about the nginx configuration the [upstream-vhost](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/#custom-nginx-upstream-vhost) annotation sets the `proxy_set_header Host $host` directive, which was pointed out in the [sendgrid documentation](https://docs.sendgrid.com/ui/account-and-settings/custom-ssl-configurations) that its needed.

The [proxy-body-size](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/#custom-max-body-size) annotation will set the [client_max_body_size](http://nginx.org/en/docs/http/ngx_http_core_module.html#client_max_body_size) nginx directive, which means that there won't be any size checking on the requests.
Furthermore the SSL redirection, and the https backend protocol annotations will ensure the HTTPS connection between the ingress and the Backend service.

The final applicable one-file configuration is the following:
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: sengrid-proxy
---
apiVersion: v1
kind: Service
metadata:
  name: sendgrid-net
  namespace: sengrid-proxy
spec:
  type: ExternalName
  externalName: sendgrid.net
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    cert-manager.io/cluster-issuer: letsencypt-prod
    nginx.ingress.kubernetes.io/proxy-body-size: "0"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/upstream-vhost: "urlxxxx.yourdoamin.com"
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
    kubernetes.io/ingress.class: "nginx"
  name: sendgrid
  namespace: sengrid-proxy
spec:
  rules:
    - host: urlxxxx.yourdoamin.com
      http:
        paths:
          - backend:
              service:
                name: sendgrid-net
                port:
                  number: 443
            path: /
            pathType: ImplementationSpecific
  tls:
    - hosts:
        - urlxxxx.yourdoamin.com
      secretName: urlxxxx.yourdoamin.com
```

With this configuration you will be able to create any external dns proxy in your Kubernetes Cluster too, so I hope this helps!
