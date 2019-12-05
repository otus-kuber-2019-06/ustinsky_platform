local kube = import "https://raw.githubusercontent.com/bitnami-labs/kube-libsonnet/master/kube.libsonnet";

local common(name) = {

  service: kube.Service(name) {
    target_pod:: $.deployment.spec.template,
  },

  deployment: kube.Deployment(name) {
    spec+: {
      template+: {
        spec+: {
          containers_: {
            common: kube.Container("common") {
              ports: [{containerPort: 80}],
              securityContext: {
                readOnlyRootFilesystem: true,
                runAsNonRoot: true,
                runAsUser: 10001,
                capabilities: {
                  drop:["all"],
                  add: ["NET_BIND_SERVICE"],
                },
              },
            },
          },
        },
      },
    },
  },
};

{
  catalogue: common("catalogue") {
    deployment+: {
      spec+: {
        template+: {
          spec+: {
            containers_+: {
              common+: {
                name: "catalogue",
                image: "weaveworksdemos/catalogue:0.3.5",
              },
            },
          },
        },
      },
    },
  },

  payment: common("payment") {
    deployment+: {
      spec+: {
        template+: {
          spec+: {
            containers_+: {
              common+: {
                name: "payment",
                image: "weaveworksdemos/payment:0.4.3",
              },
            },
          },
        },
      },
    },
  },
}

