# ustinsky_platform
ustinsky Platform repository

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
    sudo systemctl start kubelet;
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


Домашняя работа 5 
...

 ISCSI
        0. Установка kubernetes через kubespray
            0.1 Скачиваем
                git clone https://github.com/kubernetes-sigs/kubespray.git
            
            0.2 Устанавливаем рекомендованные зависимости
                sudo pip install -r requirements.txt`;

            0.3 Копируем файл пример
                cp -rfp inventory/sample inventory/mycluster

            0.4 Редактируем файл
                nano inventory/mycluster/inventory.ini

            0.5 Применяем, ждем и пользуемся
                ansible-playbook -i inventory/mycluster/inventory.ini --become --become-user=root --user=lex --key-file=~/.ssh/id_rsa cluster.yml 


        1. Устанавливаем targetcli на Ubuntu 18.04
            apt -y install targetcli-fb

        2. Создаем LVM раздел
            parted /dev/sdb
            # mklabel msdos
            # q
            parted -s /dev/sdb unit mib mkpart primary 1 100% set 1 lvm on
            pvcreate /dev/sdb1
            vgcreate vg0 /dev/sdb1
            lvcreate -l 10%FREE -n base vg0
            mkfs.ext4 /dev/vg0/base

        3. Настраиваем targetcli
            targetcli
            /> ls
            /> backstores/block create name=iscsi-disk dev=/dev/vg0/base
            /iscsi create
            /iscsi и ls 
            iqn.2003-01.org.linux-iscsi.iscsi-1.x8664:sn.c67162716271617/tpg1/
            luns/ create /backstores/block/iscsi-disk
            set attribute authentication=0
            acls/
            create wwn=iqn.2019-09.com.example.srv01.initiator01
            cd / 
            ls 
            saveconfig
            exit
            (https://kifarunix.com/how-to-install-and-configure-iscsi-storage-server-on-ubuntu-18-04/)


    4. Настраиваем worker-node
        4.1 apt -y install open-iscsi
            yum install iscsi-initiator-utils

        4.2 настроим конфиг /etc/iscsi/initiatorname.iscsi, 
        внеся туда корректное имя, которое мы использовали ранее `iqn.2019-09.com.example.srv01.initiator01`

        4.3 добавим open-iscsi в автозагрузку и запустим:
            systemctl restart iscsid open-iscsi
            systemctl enable iscsid open-iscsi

    5. Проверяем
        5.1 Запускаем под
            kubectl apply -f kubernetes-storage/iscsi/01-iscsi-pod.yaml

        5.2 Зайдем на pod
            kubectl exec -it iscsi-pod -- /bin/bash

        5.3 Сохраним
            echo "ISCSI TEST!" > /mnt/iscsi-test.txt

        5.4 Создадим snapshot
            lvcreate --snapshot --size 1G  --name ss-01 /dev/vg0/base

        5.5 Перейдем обратно в под и удалим данные
            rm -rf /mnt/iscsi-test.txt

        5.6 Удалим сам pod
            kubectl delete -f kubernetes-storage/iscsi/01-iscsi-pod.yaml

        5.7 Отключим диск ISCSI
            targetcli 
            /> backstores/block delete iscsi-disk 

        5.8 Восстановимся из снапшота 
            lvconvert --merge /dev/vg0/ss-01

        5.9 Восстановим диск ISCSI
            targetcli
            /> backstores/block create name=iscsi-disk dev=/dev/vg0/base
            /> /iscsi/iqn.2003-01.org.linux-iscsi.iscsi-1.x8664:sn.c0904cfa5297/tpg1/
            /> luns/ create /backstores/block/iscsi-disk
            exit

        5.10 Снова запусти и проверим наличие файла
            kubectl apply -f kubernetes-storage/iscsi/01-iscsi-pod.yaml
            kubectl exec -it iscsi-pod -- /bin/bash
            cat /mnt/iscsi-test.txt


Домашняя работа 6 (Debug)
1. kubectl debug
    1.1 Установим kubectl по инструкции https://github.com/aylei/kubectl-debug
        export PLUGIN_VERSION=0.1.1
        # linux x86_64
        curl -Lo kubectl-debug.tar.gz https://github.com/aylei/kubectl-debug/releases/download/v${PLUGIN_VERSION}/kubectl-debug_${PLUGIN_VERSION}_linux_amd64.tar.gz
        tar -zxvf kubectl-debug.tar.gz kubectl-debug
        sudo mv kubectl-debug /usr/local/bin/

        # if your kubernetes version is v1.16 or newer
        kubectl apply -f https://raw.githubusercontent.com/aylei/kubectl-debug/master/scripts/agent_daemonset.yml
        # if your kubernetes is old version(<v1.16), you should change the apiVersion to extensions/v1beta1, As follows
        wget https://raw.githubusercontent.com/aylei/kubectl-debug/master/scripts/agent_daemonset.yml
        sed -i '' '1s/apps\/v1/extensions\/v1beta1/g' agent_daemonset.yml
        kubectl apply -f agent_daemonset.yml
        mv agent_daemonset.yml agent_daemonset_old.yml

    1.2 Пробуем запустить strace и получаем ошибку
            
        1.2.1 Запускаем пробный под
            kubectl create ns test1
            kubectl run nginx --image=nginx --port=80 -n test1 --generator=run-pod/v1

        1.2.2 Из другого терминала заходим kubectl debug-ом 
            kubectl debug nginx -n test1 --port-forward

        1.2.3 Пробуем запустить strace
            bash-5.0# strace -p6 -c
            strace: test_ptrace_get_syscall_info: PTRACE_TRACEME: Operation not permitted
            strace: attach: ptrace(PTRACE_ATTACH, 6): Operation not permitted

        1.2.4 Видим ошибку. Нет прав PTRACE_TRACEME

        1.2.5 Ищем контейнер
            $ docker ps | grep ne
            00289bcf1ff1        nicolaka/netshoot:latest   "bash"                   10 seconds ago      Up 9 seconds                                   friendly_mirzakhani
            206bfb03f042        4689081edb10               "/storage-provisioner"   36 minutes ago      Up 36 minutes                                  k8s_storage-provisioner_storage-provisioner_kube-system_83577e77-9923-4777-bd3d-a64e2246850c_0
            dac0e02cb0fb        k8s.gcr.io/pause:3.1       "/pause"                 36 minutes ago      Up 36 minutes                                  k8s_POD_storage-provisioner_kube-system_83577e77-9923-4777-bd3d-a64e2246850c_0

        1.2.6 Смотрим docker capabilities
            $ docker inspect 00 | less 
            ...
             "CapAdd": null
            ...

        1.2.7 Права не добавляются

    1.3 Правим
    
        1.3.1 Меняем в файле agent_daemonset.yaml

            image: aylei/debug-agent:0.0.1
            на 
            image: aylei/debug-agent:latest

        1.3.2 Удаляем старый daemonset
            kubectl delete daemonset debug-agent

        1.3.3 Ставим новый
            kubectl apply -f 01-agent-daemonset.yaml

        1.3.4 Проверяем работу strace
            bash-5.0# strace -p7 -c
            strace: Process 7 attached
            ^Cstrace: Process 7 detached
            % time     seconds  usecs/call     calls    errors syscall
            ------ ----------- ----------- --------- --------- ----------------
            21.19    0.000153          76         2           writev
            21.05    0.000152          38         4           close
            16.20    0.000117          19         6           epoll_wait
            14.54    0.000105          52         2           sendfile
            5.26    0.000038          19         2           stat
            4.85    0.000035          17         2           accept4
            4.16    0.000030           7         4           recvfrom
            3.74    0.000027          13         2           openat
            3.46    0.000025          12         2           write
            2.35    0.000017           8         2           epoll_ctl
            1.94    0.000014           7         2           setsockopt
            1.25    0.000009           4         2           fstat
            ------ ----------- ----------- --------- --------- ----------------
            100.00    0.000722                    32           total

        1.3.5 Проверяем права
            $ docker inspect 22 | less
            ... 
            "CapAdd": [
                    "SYS_PTRACE",    
                    "SYS_ADMIN"
            ]
            ...

        1.3.6 Забавно получается 
            Образ nicolaka/netshoot:latest не меняется. Но меняется запуск. 
            Образ aylei/debug-agent берется другой. CapAdd для debug-agent остается тем же ("CapAdd": null). 
            Но запуск контенера netshoot меняется. Добавляются права SYS_PTRACE

2 iptables-tailer
    2.1 Установка https://github.com/piontec/netperf-operator
        git clone https://github.com/piontec/netperf-operator.git 

    2.2 Запустить манифесты
        kubectl apply -f ./deploy/crd.yaml
        kubectl apply -f ./deploy/rbac.yaml
        kubectl apply -f ./deploy/operator.yaml

    2.3 Запустим пример
        kubectl apply -f ./deploy/cr.yaml
        kubectl describe netperf.app.example.com/example

    2.4 Ставим политику (включаем логирование в iptables) и смотрим как изменился вывод
        kubectl apply -f kit/netperf-calico-policy.yaml
        kubectl delete -f netperf-operator/deploy/cr.yaml
        kubectl apply -f netperf-operator/deploy/cr.yaml
        kubectl describe netperf.app.example.com/example

    2.5 Получаем доступ SSH к ноде GKE
     
        2.5.1 Получаем IP адрес узлов кластера
            gcloud beta compute --project "studied-glow-255313" ssh --zone "us-central1-a" "gke-standard-cluster-3-default-pool-a7bab0cf-g9gm"

        2.5.2 Подключаемся к ноде по SSH и смотрим iptables
            iptables --list -nv | grep DROP - счетчики дропов ненулевы
            iptables --list -nv | grep LOG - счетчики с действием логирования ненулевые
            journalctl -k | grep calico

    2.6 Запустим iptailer
        2.6.1 Применим
            kubectl apply -f kit/iptables-tailer.yaml 
            kubectl describe daemonset kube-iptables-tailer -n kube-system

        2.6.2 Применим ServiceAccount
            kubectl apply -f kit/kit-serviceaccount.yaml
            kubectl apply -f kit/kit-clusterrole.yaml
            kubectl apply -f kit/kit-clusterrolebinding.yaml 
            kubectl describe daemonset kube-iptables-tailer -n kube-system

        2.6.3 Пересоздадим netperf
            kubectl delete -f netperf-operator/deploy/cr.yaml
            kubectl apply -f netperf-operator/deploy/cr.yaml
            kubectl describe netperf.app.example.com/example

        2.6.4 Проверяем
            kubectl get events -A
            kubectl describe pod --selector=app=netperf-operator
            Видим что пакеты дропаются

        2.7 Иcправим


Домашняя работа 7 (operators)
1. CRD CR Mysql

    1.1 Создадим 
        kubectl apply -f deploy/crd.yml
        kubectl apply -f deploy/cr.yml

    1.2 Взаимодействие с объектами
        kubectl get crd
        kubectl get mysqls.otus.homework
        kubectl describe mysqls.otus.homework mysql-instance


    1.3 Добавим спецификацию полей (добавляется поле validation)
        kubectl delete mysqls.otus.homework mysql-instance
        kubectl apply -f deploy/crd.yaml
        kubectl apply -f deploy/cr.yaml

    1.4 Запустим оператор
        apt install python3-pip
        pip3 install kopf
        PATH="$PATH:/home/lex/.local/bin/"
        pip3 install kubernetes jinja2
        kopf run mysql-operator.py

    1.5 Почему объект создался, хотя мы создали CR, до того, как запустили контроллер?
        Ответ из документации
        https://kopf.readthedocs.io/en/latest/walkthrough/starting/

        Note that the operator has noticed an object created before the operator was even started, 
        and handled it – since it was not handled before.

        Обратите внимание, что оператор заметил объект, созданный еще до того, как оператор был запущен,
         и обработал его - поскольку он не был обработан ранее.

    1.6 Удалим все ресурсы созданные контроллером
        kubectl delete mysqls.otus.homework mysql-instance
        kubectl delete deployments.apps mysql-instance
        kubectl delete pvc mysql-instance-pvc
        kubectl delete pv mysql-instance-pv
        kubectl delete svc mysql-instance

    1.7 Добавим код и запустим
        kopf run mysql-operator.py
        kubectl apply -f deploy/cr.yaml
        kubectl get pvc

    1.8 Заполним базу данных
        1.8.1 export MYSQLPOD=$(kubectl get pods -l app=mysql-instance -o jsonpath="{.items[*].metadata.name}")
        
        1.8.2 kubectl exec -it $MYSQLPOD -- mysql -u root -potuspassword -e "CREATE TABLE test ( id \
              smallint unsigned not null auto_increment, name varchar(20) not null, constraint \
              pk_example primary key (id) );" otus-database
        
        1.8.3 kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "INSERT INTO test ( id, name ) \
              VALUES ( null, 'some data' );" otus-database 
                      

        1.8.4 kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "INSERT INTO test ( id, name ) \
              VALUES ( null, 'some data-2' );" otus-database

    1.9 Посмотрим содержимое таблицы
        kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "select * from test;" otus-database


    1.10 Удалим 
        kubectl delete mysqls.otus.homework mysql-instance
        kubectl get pv
        kubectl get jobs.batch

    1.11 Создадим заново
        kubectl apply -f deploy/cr.yml
        kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "select * from test;" otus-database
        kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "select * from test;" otus-database
        export MYSQLPOD=$(kubectl get pods -l app=mysql-instance -o jsonpath="{.items[*].metadata.name}")
        kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "select * from test;" otus-database

        #kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "select * from test;" otus-database
        mysql: [Warning] Using a password on the command line interface can be insecure.
        +----+-------------+
        | id | name        |
        +----+-------------+
        |  1 | some data   |
        |  2 | some data-2 |
        +----+-------------+



2 Создадим docker-контейнер
    2.1 Dockerfile 
        Dockerfile:
            FROM python:3.7
            COPY templates ./templates
            COPY mysql-operator.py ./mysql-operator.py
            RUN pip install kopf kubernetes pyyaml jinja2
            CMD kopf run /mysql-operator.py

    2.2 Отправлем в DockerHub
        docker build ./build/ --tag ustinsky/mysql-operator:v0.0.1
        docker images
        docker tag 07c37 ustinsky/mysql-operator:v0.0.1
        docker login
        docker push ustinsky/mysql-operator

    2.3 Скачаем 
        wget https://gist.githubusercontent.com/Evgenikk/581fa5bba6d924a3438be1e3d31aa468/raw/99429270c474cc434748e1058919e27df01d9a48/service-account.yml
        wget https://gist.githubusercontent.com/Evgenikk/581fa5bba6d924a3438be1e3d31aa468/raw/99429270c474cc434748e1058919e27df01d9a48/role.yml
        wget https://gist.githubusercontent.com/Evgenikk/581fa5bba6d924a3438be1e3d31aa468/raw/99429270c474cc434748e1058919e27df01d9a48/ClusterRoleBinding.yml
        wget https://gist.githubusercontent.com/Evgenikk/581fa5bba6d924a3438be1e3d31aa468/raw/619023d01e49ca3702357d4fded4d054cd523a9a/deploy-operator.yml

    2.4 Переустановим minikube
        minikube delete && minikube start

    2.5 Применим манифесты
        kubectl apply -f deploy/crd.yml
        kubectl apply -f service-account.yml
        kubectl apply -f role.yml
        kubectl apply -f ClusterRoleBinding.yml 
        kubectl apply -f deploy-operator.yml
        kubectl apply -f deploy/cr.yml

    2.6 Проверяем
        $ kubectl get pvc
        NAME                        STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
        backup-mysql-instance-pvc   Bound    pvc-5f06a495-0624-49d7-aac0-4682b2cfaba2   1Gi        RWO            standard       2m47s
        mysql-instance-pvc          Bound    pvc-bcad5009-d14c-4ef2-aad4-993d6e337313   1Gi        RWO            standard       2m48s

    2.7 Заполним базу данных
        2.7.1 export MYSQLPOD=$(kubectl get pods -l app=mysql-instance -o jsonpath="{.items[*].metadata.name}")
        
        2.7.2 kubectl exec -it $MYSQLPOD -- mysql -u root -potuspassword -e "CREATE TABLE test ( id \
              smallint unsigned not null auto_increment, name varchar(20) not null, constraint \
              pk_example primary key (id) );" otus-database
        
        2.7.3 kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "INSERT INTO test ( id, name ) \
              VALUES ( null, 'some data' );" otus-database 
                      

        2.7.4 kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "INSERT INTO test ( id, name ) \
              VALUES ( null, 'some data-2' );" otus-database

    2.8 Посмотрим содержимое таблицы
        kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "select * from test;" otus-database

    2.9 Удалим
        kubectl delete mysqls.otus.homework mysql-instance
        kubectl get pv
        kubectl get jobs.batch

    2.10 И создадим заново
        kubectl apply -f deploy/cr.yml
        export MYSQLPOD=$(kubectl get pods -l app=mysql-instance -o jsonpath="{.items[*].metadata.name}")
        kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "select * from test;" otus-database

        #kubectl exec -it $MYSQLPOD -- mysql -potuspassword -e "select * from test;" otus-database
        mysql: [Warning] Using a password on the command line interface can be insecure.
        +----+-------------+
        | id | name        |
        +----+-------------+
        |  1 | some data   |
        |  2 | some data-2 |
        +----+-------------+