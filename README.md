# Enuygun-DevOps-Bootcamp
### Yapılacaklar

1 - Terraform ile Google Cloud Platform&apos; da  Kubernetes Cluster kurulumu

2 - Kubernetes üzerine MySQL kurulumu

3 - Kubernetes üzerine WordPress kurulumu

4 - Ingress tanımı ile dışardan trafik alması için domain ayarının yapılması

# Readme.md

# 1 - Terraform İle GCP&apos;de Kubernetes Kurulumu



İlk olarak terraform dosyası hazırlanır.


#### main.tf　

```yaml
provider "google" {
 project = "deft-epoch-361312"
 region  = "europe-west3"
 zone    = "europe-west3-a"
}
resource "google_compute_network" "vpc_network" {
        name = "project-network"
        auto_create_subnetworks = "true"
}
resource "google_container_cluster" "bootcampodev" {
        name = "project-gke"
        remove_default_node_pool = true
        initial_node_count       = 1
        network    = google_compute_network.vpc_network.name
}
resource "google_service_account" "nodepool" {
        account_id   = "project-serviceaccount"
        display_name = "Project Service Account"
}
resource "google_container_node_pool" "primary_preemptible_nodes" {
        name       = "project-node-pool"
        cluster    = google_container_cluster.bootcampodev.name
        node_count = 1

        node_config {
                preemptible  = true
                               machine_type = "e2-medium"

                        service_account = google_service_account.nodepool.email
                        oauth_scopes    = [
                        "https://www.googleapis.com/auth/cloud-platform"
        ]
  }
}
```

Terraform init denilerek main.tf yazılan dosya initialize edilir.

`$ terraform init`

![terraform init](https://user-images.githubusercontent.com/85456556/188467524-3a03118f-96c1-4827-83f9-11bb4d91b850.JPG)

> terraform initializing

Bu komutu girdiğimizde Terraform yapılacak olan planı gösterir.

`$ terraform plan --out plan.out`

![plan_out apply](https://user-images.githubusercontent.com/85456556/188473457-2968ad79-d19a-45d5-8e9e-4cb1516efa9e.JPG)
> terraform plan çıktısı

Daha sonra terraform apply denilerek terraform tarafından oluşturulan plandaki eylemlerin gerçekleştirilmesi sağlanır.

`$ terraform apply "plan.out"`

![terraform apply tamamlandi_15](https://user-images.githubusercontent.com/85456556/188474664-f7785f0c-b54c-4d47-b58e-8b91307c1e04.JPG)

> terraform apply çıktısı

Ardından Google Cloud Platform&apos;a gidilerek instance ve Kubernetes cluster&apos;ın oluştuğu görülür.


![olusturulan instance gcp goruntusu_17](https://user-images.githubusercontent.com/85456556/188481041-15e92968-b252-4245-940e-1006a85e2ac5.JPG)

> Oluşturulan instance görüntüsü

![kubernetes cluster son hali_20](https://user-images.githubusercontent.com/85456556/188482052-3dd6fda4-4ac1-432c-b8dd-61ca7732adc7.JPG)
> Oluşturulan Kubernetes clusterın görüntüsü_1


![cluster son hali_21](https://user-images.githubusercontent.com/85456556/188482363-7562adff-43b4-44f4-89b6-511d37aa2227.JPG)


> Oluşturulan Kubernetes clusterın görüntüsü_2

# 2 - Kubernetes Üzerine MySQL Kurulumu

İlk olarak bir önceki kısımda kurulan "project-gke" isimli cluster&apos;ın yanında bulunan 3 noktaya tıklanır. "connect" denilerek Google Cloud Shell ekranına bağlanılır.


![gcp_cloud](https://user-images.githubusercontent.com/85456556/188493472-ced35fc1-1597-4828-a817-31711ce8753e.JPG)

> Cloud Shell bağlantısı

## Kurulum Adımları

1.MYSQL için Secret Oluşturma

2.MYSQL için PVC Oluşturma

3.MYSQL için Deployment Oluşturma

4.MYSQL için Service Oluşturma

### 1.adım : MYSQL için Secret Oluşturma

MYSQL, kurulurken root parola gereklidir. Deployment dosyasında root parolası ayarlanabilir.
Kullanılmadan önce öncelikle şifrenin kodlanması gereklidir.
Bu parolayı kodlamak için aşağıdaki komut kullanılabilir.

`$ echo -n 'sqlmysql123321' | base64`

Oluşan çıktı aşağıdaki gibi olmalıdır.

`c3FsbXlzcWwxMjMzMjE=`

Ardından mysql-secret.yaml oluşturulur.

![mysql_secret_yaml_nano_2](https://user-images.githubusercontent.com/85456556/188498666-f1a40829-d9ac-4dfe-a4ce-1f7055de2f21.JPG)

Oluşturulan yaml aşağıdaki gibi yazılır.
```yaml
apiVersion: v1
kind: Secret
metadata:
      name: wp-db-secrets
type: Opaque
data:
  MYSQL_ROOT_PASSWORD: c3FsbXlzcWwxMjMzMjE=
```

Burada secret dosyalarını yapılandırmak için kullanılan varsayılan tür, Opaque&apos;dır.
Yaml kaydedilip çıkılır ve aşağıdaki komut kullanılarak yaml file çalıştırılır.
`$ kubectl apply -f mysql-secret.yaml`

![kubectl apply mysql_secret_yaml_4](https://user-images.githubusercontent.com/85456556/188500077-bcb02eab-48ac-4039-8e4f-23e63fd19bdb.JPG)

Aşağıdaki komut ile oluşturulan secreti görüntülenir.

`$ kubectl get secret`

![secretlara bakilir_5](https://user-images.githubusercontent.com/85456556/188500281-36561e2d-ceb7-4528-ba32-ad74b5c323d7.JPG)

### 2.adım : MYSQL için PVC Oluşturma
Kubernetes teki pod, varsayılan olarak verileri tutmaz. Verileri Kubernetes te depolamak için depolamaya ihtiyaç duyulur. Google Cloud Platform tarafından sunulan standard storage class kullanılabilir. Bu şekilde Persistent Volume (PV) yerine Persistent Volume Claim (PVC) oluşturulabilinilir.

Aşağıdaki komut ile mysql-volume.yaml oluşturulur.

`$ nano mysql-volume.yaml`

![mysql_volume_yaml olusturulur_6](https://user-images.githubusercontent.com/85456556/188500504-c7c932b9-cf64-4228-8622-3f0c42d1fd46.JPG)

Oluşturulan yaml aşağıdaki gibi yazılır.

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
      name: mysql-volume
spec:
      accessModes:
      -   ReadWriteOnce
      resources:
           requests:
             storage: 10Gi
      storageClassName: standard-rwo
```

Yaml kaydedilip çıkılır ve aşağıdaki komut kullanılarak yaml file çalıştırılır.

`$ kubectl apply -f mysql-volume.yaml`

Aşağıdaki şekilde oluşturulan PVC&apos; nin GCP&apos; de ayrıntılı olarak görüntülenebilir.

![pvc_volum](https://user-images.githubusercontent.com/85456556/188502978-c9fb76d0-922e-4e27-9837-a17c7ecced04.JPG)
### 3.adım : MYSQL için Deployment Oluşturma

Şifre oluşturuldu ve depolama alanı ayrıldı. Şu anki aşamada deployment dosyası oluşturularak MYSQL deploy edilir. 

Aşağıdaki komut ile mysql.yaml oluşturulur.

`$ nano mysql.yaml`

Oluşturulan yaml aşağıdaki gibi yazılır.

```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
      name: mysql
      labels:
        app: mysql
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: database
        image: mysql:5.7
        args:
          # mount volume
          - "--ignore-db-dir=lost+found"
        # add root password
        envFrom:
          - secretRef:
              name: wp-db-secrets
        ports:
          - containerPort: 3306
        volumeMounts:
        - name: mysql-data
                mountPath: /var/lib/mysql
      volumes:
      - name: mysql-data
        persistentVolumeClaim:
          claimName: mysql-volume
```
Kind seçeneği olarak ReplicaSet seçilmiştir. Versiyon olarak MYSQL 5.7 kullanılmıştır. Parola envFrom kullanılarak daha önce oluşturulan secret dosyasından çekilir. Volume kısmında da persistentVolumeClaim seçeneği kullanılarak monte edilir ve oluşturulan mysql-volume dosyası kullanılır.

Yaml kaydedilip çıkılır ve aşağıdaki komut kullanılarak yaml file çalıştırılır.

`$ kubectl apply -f mysql.yaml`

Oluşturulan mysql podun çalışma durumuna ve detaylarına aşağıdaki komut ile erişilir.

`$ kubectl describe pod <pod_name>`

![detayli podlara bakilir_13](https://user-images.githubusercontent.com/85456556/188506320-3e544a73-f413-4e48-835b-4dd185c2c693.JPG)

### 4.adım : MYSQL için Service Oluşturma
Bir önceki adımda MYSQL pod çalıştırıldı. Bu uygulama MYSQL veritabanını kullanmak isterse MYSQL&apos; e doğrudan erişilemediğinden dolayı bir service oluşturulması gerekir. Oluşturulan service ile MYSQL Pod&apos; a erişim gerçekleştirilir.

Aşağıdaki komut ile mysql.yaml oluşturulur.

`$ nano mysql-service.yaml`

Oluşturulan yaml aşağıdaki gibi yazılır.

```yaml
apiVersion: v1
kind: Service
metadata:
      name: mysql-service
spec:
     ports:
     -    port: 3306
          protocol: TCP
     selector:
         app: mysql
```

Service türü ClusterIP&apos;dir. Type olarak belirtilmediği sürece varsayılan olarak ClusterIP ayarlanır. ClusterIP ile yalnızca internal podlar MYSQL pod&apos; a  erişebilir.

Yaml kaydedilip çıkılır ve aşağıdaki komut kullanılarak yaml file çalıştırılır.

`$ kubectl apply -f mysql-service.yaml`

Çalışan servislere aşagıdaki komut ile erişilebilinir.

`$ kubectl get svc`

Komut çalıştırıldığında aşağıdaki gibi bir sonuç oluşur.


![serviceler goruntulenir_17](https://user-images.githubusercontent.com/85456556/188508787-1e30086f-0bc1-4aaa-8cb8-83d5b575d78c.JPG)

Servislerin çalıştığı görülür. Ardından MYSQL&apos; de bir veri tabanı oluşturulmalıdır. Bu nedenle pod ismi ile MYSQL&apos; Pod&apos;  a girilir.

`$ kubectl exec -it <pod_name> -- bash`

Üzerine çalışılan mysql-x9mtw olduğu için bu isim girilmiştir.

`$ kubectl exec -it mysql-x9mtw -- bash`

MYSQL&apos;  e giriş yapılıp şifre girilmesi için aşağıdaki komut girilir.

` mysql -u root -p`

WordPress isminde veri tabanı oluşturulur. Aşağıdaki komut girilir.

`CREATE DATABASE wordpress`

Ardından oluşturulan veri tabanının oluştuğu aşağıdaki komut girilerek görülür.

` show databases;`


Yapılan işlemler ve çıktıları aşağıdaki gibi olur.

![sifre olusturulup cikilirson_18](https://user-images.githubusercontent.com/85456556/188510146-a7a2571a-c318-4016-8802-bcb6db619572.JPG)

Bu işlemden sonra MYSQL kurulumu tamamlanmıştır ve Wordpress&apos;  e bağlanmaya hazır hale gelmiştir.

# 3 - Kubernetes Üzerine WordPress Kurulumu

WordPress verileri depolamak için MYSQL&apos;  e ihtiyaç duyar. Bir önceki kısımda MYSQL kurulumu yapılmıştı. Bu kurulumda ise WordPress&apos;  in Kubernetes cluster&apos; ına nasıl dağıtılacağı ve MYSQL e nasıl bağlanacağı aşamalı olarak yapılacaktır.

## Kurulum Adımları

1.WordPress için PVC Oluşturma

2.WordPress için Deployment Oluşturma

3.WordPress için Service Oluşturma

WordPress metin içeriğini MYSQL  de saklar. Bu nedenle WordPress ayrıca görüntüleri depolamak için ayrı bir depolama alanına ihtiyaç duyar.

Aşağıdaki yaml kullanılarak PV ve PVC dosyaları oluşturulur.

### 1.adım: WordPress için PVC Oluşturma

İlk olarak aşağıdaki komut ile wp-volume.yaml oluşturulur.

`$ nano wp-volume.yaml`

Oluşturulan yaml aşağıdaki gibi yazılır.

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
      name: wordpress-volume
spec:
     accessModes:
     -    ReadWriteOnce
     resources:
         requests:
           storage: 10Gi
     storageClassName: standard
```

Yaml kaydedilip çıkılır ve aşağıdaki komut kullanılarak yaml file çalıştırılır.

`$ kubectl apply -f wp-volume.yaml`

Aşağıdaki komutlar ile PV ve PVC&apos;  lere bakılır.

`$ kubectl get pv`

`$ kubectl get pvc`

Komutlar girildiğinde aşağıdaki gibi bir çıktı oluşur.

![pv ve pvc](https://user-images.githubusercontent.com/85456556/188513487-392fd2f4-6aab-4977-bb57-0b2135c850d2.JPG)

### 2.adım: WordPress için Deployment Oluşturma

Bu adımda WordPress Pod&apos;  u oluşturmaya başlanır.

İlk olarak aşağıdaki komut ile deployment yaml oluşturalım.

`$ nano wp.yaml`

Oluşturulan yaml aşağıdaki gibi yazılır.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
      name: wordpress
spec:
     replicas: 1
     selector:
         matchLabels:
           app: wordpress
     template:
       metadata:
         labels:
           app: wordpress
       spec:
         containers:
           - name: wordpress
             image: wordpress:5.8.3-php7.4-apache
             ports:
             - containerPort: 80
               name: wordpress
             volumeMounts:
               - name: wordpress-data
                 mountPath: /var/www
             env:
               - name: WORDPRESS_DB_HOST
                 value: mysql-service.default.svc.cluster.local
               - name: WORDPRESS_DB_PASSWORD
                 valueFrom:
                   secretKeyRef:
                     name: wp-db-secrets
                     key: MYSQL_ROOT_PASSWORD
               - name: WORDPRESS_DB_USER
                 value: root
               - name: WORDPRESS_DB_NAME
                 value: wordpress
         volumes:
           - name: wordpress
             persistentVolumeClaim:
               claimName: wordpress-volume
```

Burada volumeMounts, WordPress in yolunu bağlamak ve verileri PV ye göndermek için kullanılır. WORDPRESS_DB_HOST, MYSQL podunu bağlamak için kullanılır.

Yaml kaydedilip çıkılır ve aşağıdaki komut kullanılarak yaml file çalıştırılır.

`$ kubectl apply -f wp.yaml`

Aşağıdaki komut girilerek çalışan podlara bakılır.

`$ kubectl get pods`

![kubectl get pods](https://user-images.githubusercontent.com/85456556/188515667-ca75a305-e1a2-4697-aaa3-9c675cb6b9c8.JPG)


### 3.adım: WordPress için Service Oluşturma

WordPress podunun çalıştığı bir önceki adımda görülmüştür.  WordPress pod&apos; a doğrudan erişilemez. WordPress uygulamasına erişebilmek için LoadBalancer kullanılması gerekir.

Aşağıdaki komut ile wp-service.yaml oluşturulur.

`$ nano wp-service.yaml`

Oluşturulan yaml aşağıdaki gibi yazılır.

```yaml
apiVersion: v1
kind: Service
metadata:
      name: wordpress-service
spec:
     type: LoadBalancer
     selector:
         app: wordpress
     ports:
          -  name: http
             protocol: TCP
             port: 80
             targetPort: 80

```

Yaml kaydedilip çıkılır ve aşağıdaki komut kullanılarak yaml file çalıştırılır.

`$ kubectl apply -f wp-service.yaml`



Aşağıdaki komut ile oluşturulan servis görüntülenir.

`$ kubectl get svc`

wordpress-service aşağıdaki gibi görüntülenir. Burada EXTERNAL-IP ye bağlanılarak WordPress kurulumuna geçilir.

![kubectl get svc](https://user-images.githubusercontent.com/85456556/188519504-fa51a0e7-1b4e-4a7b-b718-e1c0cfe87dc5.JPG)

Aşağıdaki IP ye bağlanılır.

`http://34.159.216.163` 

![wordpress ana sayfasi](https://user-images.githubusercontent.com/85456556/188519794-af3ed987-223c-404d-bbdb-a7177e97ef7a.JPG)

> WordPress Kurulum Sayfası

Dil seçilip "Continue" butonuna basılıp devam edilir.

Aşağıdaki gibi  kullanıcı oluşturma sayfası gelir.

![wordpress welcome sayfasi_yazili](https://user-images.githubusercontent.com/85456556/188519914-36aa1596-7d27-4841-9077-ad41b273fc30.JPG)

> WordPress Kullanıcı Oluşturma Sayfası


Burada kullanıcı oluşturulur.

Aşağıdaki sayfada oluşturulan şifre girilip "Log In" butonuna tıklanır.

![wordpress isim soyisim sifre](https://user-images.githubusercontent.com/85456556/188519998-19036ea6-a280-4f21-9ef2-91697f13a901.JPG)

> WordPress Giriş Sayfası

Ardından aşağıdaki gibi WordPress Ana Ekranı elde edilmiş olur.

![wordpress giris yapildiktan sonraki ana sayfa sonnn](https://user-images.githubusercontent.com/85456556/188520085-bd9b9910-c3b6-4645-9bf1-b7c076401de2.JPG)


> WordPress Ana Sayfası



# 4 -Ingress Tanımı İle Dışardan Trafik Alması İçin Domain Ayarının Yapılması

 Ingress ile erişebilmek için öncelikle servis oluşturulması gerekir.

Aşağıdaki komut ile wp-service.yaml oluşturulur.

`$ nano wp-service.yaml`

Oluşturulan yaml aşağıdaki gibi yazılır.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: wordpress-service
  labels:
    app: wordpress
spec:
  type: NodePort
  selector:
    app: wordpress
  ports:    
  - port: 80
    targetPort:80
```

Yaml kaydedilip çıkılır ve aşağıdaki komut kullanılarak yaml file çalıştırılır.

`$ kubectl apply -f wp-service.yaml`

Aşağıdaki komut ile oluşturulan servis görüntülenir.

`$ kubectl get svc`

![servicenode](https://user-images.githubusercontent.com/85456556/188518151-d89d2b9f-2826-4d08-b872-409f907d2e93.JPG)

Servis oluşturulduktan sonra ingress global static ip oluşturulur.


![wpip](https://user-images.githubusercontent.com/85456556/188721423-06bba2ba-3345-41ae-883e-c399a6fd9fcb.JPG)


Daha sonra aşağıdaki komut ile ingress-static-ip.yaml oluşturulur.

`$ nano ingress-static-ip.yaml `

Oluşturulan yaml aşağıdaki gibi yazılır.

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: wordpress
  annotations:
    kubernetes.io/ingress.class: "gce"
    kubernetes.io/ingress.global-static-ip-name: wp-ip
  labels:
    app: wordpress
spec:
  rules:
  - http:
      paths:
      - path: "/*"
        pathType: ImplementationSpecific
        backend:
          service:
            name: wordpress-service
            port:
              number: 80
```

Yaml kaydedilip çıkılır ve aşağıdaki komut kullanılarak yaml file çalıştırılır.

`$ kubectl apply -f ingress-static-ip.yaml `

Aşağıdaki komut kullanılarak ingress adresi görülür.

![getingress](https://user-images.githubusercontent.com/85456556/188518616-1789bbbc-dfd3-4d3d-ade3-608005ca4e77.JPG)

Bu adrese girildiğinde WordPress ekranının geldiği görülür.


![kubernetes wp ekran](https://user-images.githubusercontent.com/85456556/188722619-af8b6add-f3c4-4834-91a0-2e68aad81412.JPG)


###Özet


Bu projede öncelikle, Terraform ile Google Cloud Platform&apos; a Kubernetes Cluster kuruldu. Daha sonra buraya bağlanılarak Kubernetes üzerine MYSQL kurulumu gerçekleştirildi. Ardından da WordPress kuruldu ve MYSQL ile bağlantısı gerçekleştirildi. Son olarak da Ingress ile dışarıdan trafik alması sağlandı.
