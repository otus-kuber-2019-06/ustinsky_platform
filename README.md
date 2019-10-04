# ustinsky_platform
ustinsky Platform repository

Домашняя работа 1 (kuber-intro)

1. Установка kubectl
    1.1 Скачиаем
        curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
    1.2 Даем права
        chmod +x ./kubectl
    1.3 Переносим в /usr/local/bin
        sudo mv ./kubectl /usr/local/bin/kubectl
    1.4 Настраиваем автодополнение
        source <(kubectl completion bash) # setup autocomplete in bash into the current shell, bash-completion package should be installed first.
        echo "source <(kubectl completion bash)" >> ~/.bash_profile

2.  Установка minikube
    2.1 Проверяем наличие поддержки аппаратной виртуализации
        grep -E --color 'vmx|svm' /proc/cpuinfo
    2.2 Устанавливаем VirtualBox

    2.3 Скачиваем minikube
        curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && chmod +x minikube

    2.4 Устанавливаем minikube
        sudo install minikube /usr/local/bin

3. Установка kind (https://kind.sigs.k8s.io/)
    1. Ставим
        GO111MODULE="on" go get sigs.k8s.io/kind@v0.5.1 && kind create cluster
    2. Опредеяем настройки kubectl
        export KUBECONFIG="$(kind get kubeconfig-path --name="kind")"
    3. Проверяем кластер
        kubectl cluster-info

4. Запуск minikube 
    minikube start

5. Просмотр текущей конфигурации
    5.1 kubectl 
        kubectl config view
    5.2 Подключение к кластеру
        kubectl cluster-info

6.  Kubernetes Dashboard
    6.1 Применяем
        kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta1/aio/deploy/recommended.yaml
    6.2 Доступ (https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/)
        6.2.1 dashboard-service-account.yaml

            apiVersion: v1
            kind: ServiceAccount
            metadata:
                name: admin-user
                namespace: kube-system
        
        
        6.2.2 dashboard-role-binding.yaml

            apiVersion: rbac.authorization.k8s.io/v1
            kind: ClusterRoleBinding
            metadata:
                name: admin-user
            roleRef:
                apiGroup: rbac.authorization.k8s.io
                kind: ClusterRole
                name: cluster-admin
            subjects:
            -   kind: ServiceAccount
                name: admin-user
                namespace: kube-system

        6.2.3 Смотрим токен
            kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}') 

    6.3 Проксируем
        kubectl proxy

    6.4 Заходим на http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/ 
        используя токен

7.  k9s
    7.1 Скачиваем 
        wget https://github-production-release-asset-2e65be.s3.amazonaws.com/167596393/06956700-be26-11e9-8765-7e323b0dce92?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAIWNJYAX4CSVEH53A%2F20190826%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20190826T144828Z&X-Amz-Expires=300&X-Amz-Signature=11380ce16989a1de7bc454f6c13d3ab9784884bddde989f26cbba0dfad3aecd4&X-Amz-SignedHeaders=host&actor_id=18228849&response-content-disposition=attachment%3B%20filename%3Dk9s_0.8.2_Linux_x86_64.tar.gz&response-content-type=application%2Foctet-stream

    7.2 Распаковываем и запускаем

8.  Заходим на VM minikube
    8.1 Заходим на VM по SSH
        minikube ssh
    8.2 Проверяем устойчивость к отказам 
        docker rm -f $(docker ps -a -q)

9.  Проверяем устойчивость через kubectl
    9.1 Получаем список pod-ов для namespace kube-system
        kubectl get pods -n kube-system
    9.2 Удаляем все поды для этого namespace
        kubectl delete pod --all -n kube-system

10. Проверка что кластер находится в рабочем состоянии
    kubectl get componentstatuses
    kubectl get cs 

11. Почему происходит восcтановление системных подов после удаления
    kubelet запущен как сервис systemd. Он занимается процессом запуска pod-ов.
    Если выполнить 
    sudo systemctl stop kubelet; docker rm -f $(docker ps -a -q)
    то кластер не восстанавливается автоматически

    для запуска кластера
    sudo systemctl stop kubelet;
    после чего кластер запускает необходимые контейнеры

    core-dns реализован как Deployment с параметром replicas: 2

    так же можно сломать кластер командой 
    (kill -9 `pgrep -f docker`) &

    Не посмотрел внимательно !!!??? 
    При аварийном запуске имеется процесс coredns, при нормальной работе coredns - это несколько контейнеров

    ??? (coredns и api-server имеют разные причины восстановления)

    // сломал ( (kill -9 `pgrep -f docker`) & )
    systemd-+-VBoxService---6*[{VBoxService}]
        |-bash---sleep
        |-2*[coredns---9*[{coredns}]]
        |-dbus-daemon
        |-etcd---11*[{etcd}]
        |-getty
        |-kube-apiserver---10*[{kube-apiserver}]
        |-kube-proxy---7*[{kube-proxy}]
        |-kube-scheduler---9*[{kube-scheduler}]
        |-11*[pause]
        |-rpc.mountd
        |-rpcbind
        |-sshd---sshd---sshd---bash---pstree
        |-storage-provisi---6*[{storage-provisi}]
        |-systemd-journal
        |-systemd-logind
        |-systemd-network
        |-systemd-resolve
        `-systemd-udevd

        =======================
    systemd-+-VBoxService---6*[{VBoxService}]
        |-dbus-daemon
        |-dockerd-+-containerd-+-2*[containerd-shim-+-pause]
        |         |            |                    `-10*[{containerd-shim}]]
        |         |            |-7*[containerd-shim-+-pause]
        |         |            |                    `-9*[{containerd-shim}]]
        |         |            |-containerd-shim-+-bash---sleep
        |         |            |                 `-10*[{containerd-shim}]
        |         |            |-containerd-shim-+-etcd---11*[{etcd}]
        |         |            |                 `-10*[{containerd-shim}]
        |         |            |-containerd-shim-+-kube-controller---8*[{kube-controller}]
        |         |            |                 `-10*[{containerd-shim}]
        |         |            |-containerd-shim-+-kube-apiserver---10*[{kube-apiserver}]
        |         |            |                 `-9*[{containerd-shim}]
        |         |            |-containerd-shim-+-kube-scheduler---9*[{kube-scheduler}]
        |         |            |                 `-9*[{containerd-shim}]
        |         |            |-containerd-shim-+-kube-proxy---8*[{kube-proxy}]
        |         |            |                 `-10*[{containerd-shim}]
        |         |            |-containerd-shim-+-storage-provisi---7*[{storage-provisi}]
        |         |            |                 `-9*[{containerd-shim}]
        |         |            |-containerd-shim-+-coredns---10*[{coredns}]
        |         |            |                 `-9*[{containerd-shim}]
        |         |            |-containerd-shim-+-coredns---9*[{coredns}]
        |         |            |                 `-10*[{containerd-shim}]
        |         |            `-29*[{containerd}]
        |         `-25*[{dockerd}]
        |-getty
        |-kubelet---16*[{kubelet}]
        |-rpc.mountd
        |-rpcbind
        |-sshd---sshd---sshd---bash---pstree
        |-systemd-journal
        |-systemd-logind
        |-systemd-network
        |-systemd-resolve
        `-systemd-udevd


12. Создать Dockerfile в котором будет описан образ:
    1. Запускающий web-сервер на порту 8000
    2. Отдающий содержимое директории /app
    3. Работающий с UID 1001

13. Dockerfile: 
    1. разместить в kubernetes-intro/web 
    2. Собрать образ и разместить его в DockerHub

14. Написать манифест web-pod.yaml
    apiVersion: v1      # Версия API 
    kind: Pod           # Объект, который создаем
    metadata:
        name:           # Название Pod
        labels:         # Метки в формате key: value
            key: value
    spec:               # Описание Pod
        containers:     # Описание контейнеров внутри Pod
            - name:     # Название контейнера
              image:    # Образ из которого создается контейнер

15. Применить манифест и разметить в kubernetes-intro
    15.1 Применяем
        kubectl apply -f web-pod.yaml
    15.2 Проверяем работу 
        kubectl get pods

16. Получаем от kubernetes манифест уже запущенного pod-а 
    kubectl get pod web -o yaml

17. Получаем текущее состояние и события pod-а 
    kubectl describe pod web

18. Успешная старт pod-а дает следующие сообщения:
    1. scheduler определил где запускать pod
    2. kubelet скачал необходимый образ и запустил контейнер

19. Имитация неудачного старта 
    19.1 Добавить в web-pod.yaml несуществующий тэг и применить
        kubectl apply -f web-pod.yaml
    19.2 Проверить вывод команды 
        kubectl get pods
        kubectl describe pod web

20. Init контейнеры:
    image: busybox:1.31.0
    command: ['sh', '-c', 'wget -O- https://raw.githubusercontent.com/express42/otus-platform-snippets/master/Module-02/Introduction-to-Kubernetes/wget.sh | sh']

21. Volume:
    для контейнера:
        volumeMounts:
            -name: app
             mountPath: /app
    для pod:
        volumes:
            -name: app
             emptyDir: {}

22. Удалить запущенный под из кластера и применить обновленный манифест
    1. kubectl delete pod web
    2. kubectl get pods -w
    3. kubectl apply -f web-pod.yaml && kubectl get pods -w 

23. Проверка работы приложения
    1. kubectl port-forward --address 0.0.0.0 pod/web 8000:8000
    2. открыть в браузере http://localhost:8000/index.html

24. Kube-forwarder 

25. Добавить файлы
    1. .travis.yml
    2. .github/PULL_REQUEST_TEMPLATE.md
    
Домашняя работа 2 (kuber-security)
1. task01
    1.1 Создать Service Account bob, дать ему роль admin в рамках всего кластера
        1) nano 01-sa-bob.yaml
        apiVersion: v1
        kind: ServiceAccount
        metadata:
            name: bob

        2) nano 02-rb-bob.yaml
        apiVersion: rbac.authorization.k8s.io/v1
        kind: ClusterRoleBinding
        metadata:
            name: crb-bob
        subjects:
        -   kind: ServiceAccount
            name: bob
            apiGroup: rbac.authorization.k8s.io
        roleRef:
            kind: ClusterRole
            name: cluster-admin
            apiGroup: rbac.authorization.k8s.io

    1.2 Создать Service Account dave без доступа к кластеру
        3) nano 03-sa-dave.yaml
        apiVersion: v1
        kind: ServiceAccount
        metadata:
            name: dave

2. task02
    2.1 Создать Namespace prometheus   
    nano 01-ns-prometheus.yaml
    kind: Namespace 
    apiVersion: v1
    metadata:
        name: prometheus    

    2.2 Создать Service Account carol в этом Namespace
    nano 02-sa-carol.yaml
    apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: carol
      namespace: prometheus
      
    2.3 Дать всем Service Account в prometheus возможность 
        делать get, list, watch в отношении Pods всего кластера
        
        1) nano 03-role-pod-reader.yaml
        apiVersion: rbac.authorization.k8s.io/v1
        kind: Role
        metadata:
        name: pod-reader
        rules:
        - apiGroups: [""] 
          resources: ["pods"]
          verbs: ["get", "watch", "list"]

        2) nano 04-rb-prometheus.yaml
        apiVersion: rbac.authorization.k8s.io/v1
        kind: RoleBinding
        metadata:
            name: rb-prometheus
        subjects:
        -   kind: Group
            name: system:serviceaccounts:prometheus
            apiGroup: rbac.authorization.k8s.io
        roleRef:
            kind: Role
            name: pod-reader
            apiGroup: rbac.authorization.k8s.io

3. task03
    3.1 Создать namespace dev
        nano 01-ns-dev.yaml
        kind: Namespace 
        apiVersion: v1
        metadata:
            name: dev

    3.2 Создать Service Account jane в namespace dev
        nano 02-sa-jane.yaml
        apiVersion: v1
        kind: ServiceAccount
        metadata:
          name: jane
          namespace: dev

    3.3 Дать jane роль admin в рамках namespace dev
        nano 03-rb-jane.yaml
        apiVersion: rbac.authorization.k8s.io/v1
        kind: RoleBinding
        metadata:
            name: rb-jane
            namespace: dev
        subjects:
        -   kind: ServiceAccount
            name: jane
            namespace: dev
        roleRef:
            kind: ClusterRole
            name: admin
            apiGroup: rbac.authorization.k8s.io

    3.4 Создать Service Account ken в namespace dev
        nano 04-sa-ken.yaml
        apiVersion: v1
        kind: ServiceAccount
        metadata:
          name: ken
          namespace: dev

    3.5 Дать ken роль view в рамках namespace dev
        nano 05-rb-ken.yaml
        apiVersion: rbac.authorization.k8s.io/v1
        kind: RoleBinding
        metadata:
            name: rb-ken
            namespace: dev
        subjects:
        -   kind: ServiceAccount
            name: ken
            namespace: dev
        roleRef:
            kind: ClusterRole
            name: view
            apiGroup: rbac.authorization.k8s.io


Домашняя работа 3 (kuber-network)
    
    1. Работа с тестовым веб-приложением
        1.1. Добавление проверок Pod
            1.1.1 Добавить в описание пода
                readinessProbe:
                  httpGet:
                    path: /index.html
                    port: 80

            1.1.2 Запустить под командой 
                kubectl apply -f web-pod.yaml

            1.1.3 Проверяем запуск
                kubectl get pod/web

            1.1.4 Смотрим события запуска
                kubectl describe pod/web

            1.1.5 Добавим liveness проверку
                livenessProbe:
                    tcpSocket: { port: 8000 }

            1.1.6 Вопрос
                1. Почему следующая конфигурация валидна, но не имеет смысла?
                    livenessProbe:
                        exec:
                            command:
                                - 'sh'
                                - '-c'
                                - 'ps aux | grep my_web_server_process'
                    Ответ: В команде надо еще убрать вывод самой команды grep.
                           'ps aux | grep my_web_server_process | grep -v grep'
                           И даже в этом случае наличие процесса в списке процессов
                           не гарантирует его корректную работу. Процесс может подвиснуть, 
                           переити в deadlock. Тогда в списке процессов он будет, проверку пройдет, 
                           но работать не будет. 
                2. Бывают ли ситуации, когда она все-таки имеет смысл?
                    Ответ:
                    Возможно это используется для каких то задач, которые конечны (процесс завершиться после выполнения какой либо задачи). 
                    Далее для того чтобы отреагировала диагностика пода и убрала контейнер с завершенным процессом.

        1.2. Создание объекта Deployment
            1.2.1 Создаем файл web-deploy.yaml
                apiVersion: apps/v1
                kind: Deployment
                metadata:
                  name: web                 # Название нашего объекта Deployment
                spec:
                  replicas: 1               # Начнем с одного пода
                  selector:                 # Укажем, какие поды относятся к нашему Deployment:
                    matchLabels:            # - это поды с меткой
                    app: web                # app и ее значением web
                  template:                 # Теперь зададим шаблон конфигурации пода

            1.2.2 Удаляем старый под
                kubectl delete pod/web --grace-period=0 --force

            1.2.3 Применяем Deployment
                kubectl apply -f web-deploy.yaml

            1.2.4 Посмотрим что получилось
                kubectl describe deployment web

            1.2.5 Добавляем стратегию
                strategy:
                    type: RollingUpdate
                    rollingUpdate:
                        maxUnavailable: 0
                        maxSurge: 100%

        1.3. Добавление сервисов в кластер (ClusterIP)
            1.3.1 Создаем сервис web-svc-cip.yaml
                apiVersion: v1
                kind: Service
                metadata:
                  name: web-svc-cip
                spec:
                selector:
                  app: web
                type: ClusterIP
                ports:
                - protocol: TCP
                  port: 80
                  targetPort: 8000

            1.3.2 Применяем
                kubectl apply -f web-svc-cip.yaml

            1.3.3 Проверяем
                kubectl get services

            1.3.4 Проверяем цепочку
                iptables --list -nv -t nat

                Я так понимаю работает так
                1. цепочка OUTPUT кидает на цепочку KUBE-SERVICES
                2. KUBE-SERVICES видя IP-destination кидает на цепочку KUBE-SVC-...
                3. KUBE-SVC-... распределяет нагрузку и кидает на одну из KUBE-SEP-...
                4. KUBE-SEP-... делает DNAT на конкретную машину
 
        1.4. Включение режима балансировки IPVS
            1.4.1 Включим IPVS
                kubectl --namespace kube-system edit configmap/kube-proxy
                ищем KubeProxyConfig
                меняем mode: "" => mode: "ipvs"

            1.4.2 Перезагружаем kube-proxy
                kubectl --namespace kube-system delete pod --selector='k8s-app=kube-proxy'

            1.4.3 Создадим файл /tmp/iptables.cleanup
            *nat
            -A POSTROUTING -s 172.17.0.0/16 ! -o docker0 -j MASQUERADE
            COMMIT
            *filter
            COMMIT
            *mangle
            COMMIT

            1.4.4 Применим конфигурацию
            iptables-restore /tmp/iptables.cleanup

            1.4.5 Через 30 секунд kube-proxy восстановит правила для подов
            iptables --list -nv -t nat

            1.4.6 IPVS
            toolbox
            dnf install -y ipvsadm && dnf clean all
            dnf install -y ipset && dnf clean all
            ipvsadm --list -n

    2. Доступ к приложению извне кластера 
        2.1. Установка MetaILB в Layer2 режиме
            2.1.1 Установка
                kubectl apply -f https://raw.githubusercontent.com/google/metallb/v0.8.0/manifests/metallb.yaml
                kubectl --namespace metallb-system get all

            2.1.2 Настройка балансировщика metallb-config.yaml
                apiVersion: v1
                kind: ConfigMap
                metadata:
                    namespace: metallb-system
                    name: config
                data:
                    config: |
                        address-pools:
                            - name: default
                              protocol: layer2
                              addresses:
                                - "172.17.255.1-172.17.255.255" 

        2.2. Добавление сервиса LoadBalancer
            2.2.1 Создаем файл
                apiVersion: v1
                kind: Service
                metadata:
                    name: web-svc-lb
                spec:
                    selector:
                        app: web
                    type: LoadBalancer
                    ports:
                        - protocol: TCP
                        port: 80
                        targetPort: 8000

            2.2.2 Применяем и Проверяем
                kubectl apply -f web-svc-lb.yaml
                kubectl --namespace metallb-system logs pod/controller-7757586ff4-d8ds2
                kubectl describe svc web-svc-lb

            2.2.3 Создаем статический маршрут в основной ОС
                #minikube ip
                192.168.99.103
                #ip route add 172.17.255.0/24 via 192.168.99.103

            2.2.4 DNS через MataILB
                1. Создаем манифест coredns-svc-lb.yaml
                    ---
                    apiVersion: v1
                    kind: Service
                    metadata:
                    name: coredns-svc-lb-udp
                    annotations:
                        metallb.universe.tf/allow-shared-ip: coredns
                    namespace: kube-system
                    spec:
                    selector:
                        k8s-app: kube-dns
                    type: LoadBalancer
                    loadBalancerIP: 172.17.255.2
                    ports:
                    - protocol: UDP
                        port: 53
                        targetPort: 53
                    ---
                    apiVersion: v1
                    kind: Service
                    metadata:
                    name: coredns-svc-lb-tcp
                    annotations:
                        metallb.universe.tf/allow-shared-ip: coredns
                    namespace: kube-system
                    spec:
                    selector:
                        k8s-app: kube-dns
                    type: LoadBalancer
                    loadBalancerIP: 172.17.255.2
                    ports:
                    - protocol: TCP
                        port: 53
                        targetPort: 53

                2. Проверяем работу
                    nslookup web-svc-lb.default.svc.cluster.local 172.17.255.2

        2.3. Установка ingress-контроллера и прокси ingress-nginx
            2.3.1 Установка
                kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/mandatory.yaml

            2.3.2 Создаем файл nginx-lb.yaml
                kind: Service
                apiVersion: v1
                metadata:
                    name: ingress-nginx
                    namespace: ingress-nginx
                labels:
                    app.kubernetes.io/name: ingress-nginx
                    app.kubernetes.io/part-of: ingress-nginx
                spec:
                    externalTrafficPolicy: Local
                    type: LoadBalancer
                    selector:
                        app.kubernetes.io/name: ingress-nginx
                        app.kubernetes.io/part-of: ingress-nginx
                    ports:
                        - { name: http, port: 80, targetPort: http }
                        - { name: https, port: 443, targetPort: https }

            2.3.3 Применим
                kubectl apply -f nginx-lb.yaml
                kubectl get services -n ingress-nginx

            2.3.4 Создание Headless сервиса web-svc-headless.yaml
                apiVersion: v1
                kind: Service
                metadata:
                    name: web-svc
                spec:
                    selector:
                        app: web
                    type: ClusterIP
                    clusterIP: None
                    ports:
                        - protocol: TCP
                          port: 80
                          targetPort: 8000



        2.4. Создание правил Ingress
            2.4.1 Создаем файл web-ingress.yaml
                apiVersion: networking.k8s.io/v1beta1
                kind: Ingress
                metadata:
                    name: web
                    annotations:
                        nginx.ingress.kubernetes.io/rewrite-target: /
                spec:
                    rules:
                        - http:
                            paths:
                                - path: /web
                                  backend:
                                    serviceName: web-svc
                                    servicePort: 8000

            2.4.2 Проверяем
                kubectl apply -f web-ingress.yaml
                kubectl describe ingress/web

            
            2.4.3 Создание правил для Dashboard (пока не работает)

            2.4.4 Canary проверка
                curl -kL http://<IngressIP>/webapp
                curl -kL --header 'testapp: true'  http://<IngressIP>/webapp

        3 Для запуска:
            kubectl apply -f web-deploy.yaml
            kubectl apply -f web-svc-cip.yaml
            kubectl --namespace kube-system edit configmap/kube-proxy (ищем KubeProxyConfig и меняем mode: "" => mode: "ipvs")
            kubectl apply -f https://raw.githubusercontent.com/google/metallb/v0.8.0/manifests/metallb.yaml
            kubectl apply -f metallb-config.yaml
            kubectl apply -f web-svc-lb.yaml
            minikube ip
            ip route add 172.17.255.0/24 via <IP>
            kubectl apply -f coredns-svc-lb.yaml
            kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/mandatory.yaml
            kubectl apply -f nginx-lb.yaml
            kubectl apply -f web-svc-headless.yaml
            kubectl apply -f web-ingress.yaml
            kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta1/aio/deploy/recommended.yaml
            kubectl create -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml

Домашняя работа 4 (kuber-database)
    1. kind
        1.1 Установка 
            https://kind.sigs.k8s.io/docs/user/quick-start#installation
        
        1.2 Создаем кластер
            kind create cluster
            export KUBECONFIG="$(kind get kubeconfig-path --name="kind")"

        1.3 Создаем файл minio-statefulset.yaml
            https://raw.githubusercontent.com/express42/otus-platform-snippets/master/Module-02/Kuberenetes-volumes/minio-statefulset.yaml

        1.4 Создаем файл minio-headless-service.yaml
            https://raw.githubusercontent.com/express42/otus-platform-snippets/master/Module-02/Kuberenetes-volumes/minio-headless-service.yaml
        
    2. Проверка работы
        2.1 Используя команды
            kubectl get statefulsets
            kubectl get pods
            kubectl get pvc
            kubectl get pv
            kubectl describe <resource> <resource_name>

        2.2 Используя minio/mc
            https://github.com/minio/mc

        



