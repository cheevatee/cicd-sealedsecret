FROM registry.access.redhat.com/ubi8/ubi:latest

RUN yum --disableplugin=subscription-manager -y module enable php:8.0 \
  && yum --disableplugin=subscription-manager -y install httpd php net-tools nmap-ncat iproute iputils hostname bind-utils openldap-clients jq php-mysqlnd php-pgsql php-pdo \ 
#  && yum --disableplugin=subscription-manager -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm \
#  && yum --disableplugin=subscription-manager -y install siege \
  && yum --disableplugin=subscription-manager clean all


# mysql support only manual build via podman build

#RUN yum -y module enable mysql:8.0 && \
#    INSTALL_PKGS="policycoreutils rsync tar gettext hostname bind-utils groff-base mysql-server" && \
#    yum install -y --setopt=tsflags=nodocs $INSTALL_PKGS && \
#    rpm -V $INSTALL_PKGS && \
#    yum -y clean all --enablerepo='*' && \
#    mkdir -p /var/lib/mysql/data && chown -R mysql.0 /var/lib/mysql && \
#    test "$(id mysql)" = "uid=27(mysql) gid=27(mysql) groups=27(mysql)"

ADD php-info.php index.php /var/www/html

RUN sed -i 's/Listen 80/Listen 8080/' /etc/httpd/conf/httpd.conf \
  && sed -i 's/listen.acl_users = apache,nginx/listen.acl_users =/' /etc/php-fpm.d/www.conf \
  && sed -i 's/;clear_env = no/clear_env = no/' /etc/php-fpm.d/www.conf \
  && mkdir /run/php-fpm \
  && chgrp -R 0 /var/log/httpd /var/run/httpd /run/php-fpm \
  && chmod -R g=u /var/log/httpd /var/run/httpd /run/php-fpm

EXPOSE 8080
USER 1001
CMD php-fpm & httpd -D FOREGROUND
