#FROM docker.io/library/centos:latest
FROM quay.io/centos/centos
# work in temp for the install
WORKDIR /tmp

# copy all local files over
COPY . .

# tomcat setup from here https://linuxize.com/post/how-to-install-tomcat-9-on-centos-7/
# RUN yum update -y
RUN yum install ca-certificates
RUN update-ca-trust force-enable
# RUN cp foo.crt /etc/pki/ca-trust/source/anchors/
# RUN update-ca-trust extract
RUN yum install wget -y
RUN yum install java-1.8.0-openjdk-devel -y
RUN yum install openssl -y
# RUN keytool -importkeystore -srckeystore fortify.jks -destkeystore keystore.p12 -deststoretype PKCS12 -keypass 123456789 -storepass 123456789
RUN keytool -importkeystore -srckeystore fortify.jks -destkeystore keystore.p12 -deststoretype PKCS12 -keypass 123456789 -srcstorepass 123456789 -deststorepass 123456789
# RUN openssl pkcs12 -in keystore.p12 -nokeys -out foo.crt
RUN openssl pkcs12 -in keystore.p12 -nokeys -out foo.crt -passin pass:123456789 -passout pass:123456789
RUN cp foo.crt /etc/pki/ca-trust/source/anchors/passin 
RUN useradd -m -U -d /opt/tomcat -s /bin/false tomcat
# RUN wget https://www-eu.apache.org/dist/tomcat/tomcat-9/v9.0.48/bin/apache-tomcat-9.0.48.tar.gz
#RUN wget https://mirrors.ocf.berkeley.edu/apache/tomcat/tomcat-9/v9.0.48/bin/apache-tomcat-9.0.48.tar.gz
RUN tar -xvf apache-tomcat-9.0.48.tar.gz
RUN mv apache-tomcat-9.0.48 /opt/tomcat
RUN ln -s /opt/tomcat/apache-tomcat-9.0.48 /opt/tomcat/latest
RUN chown -R tomcat: /opt/tomcat
RUN chmod +x /opt/tomcat/latest/bin/*.sh
RUN cp tomcat.service /etc/systemd/system/tomcat.service
RUN yum install -y unzip

RUN cp mysql-connector-java-8.0.19.jar /opt/tomcat/latest/lib/mysql-connector-java-8.0.19.jar
# added from nexux
RUN wget --user=admin  --password=-------"http://nexus3-openshift-operators.apps/Fortify_SSC_Server_20.2.0.zip"
RUN unzip -o Fortify_SSC_Server_20.2.0.zip
RUN unzip -o Fortify_20.2.0_Server_WAR_Tomcat.zip
RUN wget --user=admin  --password=------ http://nexus3-openshift-operators./ssc.war
RUN mv ssc.war /opt/tomcat/latest/webapps
RUN rm -rf ./*

WORKDIR /opt/tomcat/latest/webapps
RUN rm docs/ examples/ host-manager/ manager/ ROOT/ -rf

WORKDIR /opt/tomcat/latest

EXPOSE 8080
EXPOSE 8009
EXPOSE 80443

# USER tomcat
RUN chown -R 1000840000:1000840000 /opt/tomcat
USER 1000840000
# from unit-d file https://linuxize.com/post/how-to-install-tomcat-9-on-centos-7/
ENV JAVA_HOME /usr/lib/jvm/jre
ENV JAVA_OPTS -Djava.security.egd=file:///dev/urandom
ENV CATALINA_BASE /opt/tomcat/latest
ENV CATALINA_HOME /opt/tomcat/latest
ENV CATALINA_PID /opt/tomcat/latest/temp/tomcat.pid
ENV CATALINA_OPTS -Xms512M -Xmx1024M -server -XX:+UseParallelGC
ENTRYPOINT /opt/tomcat/latest/bin/catalina.sh run
