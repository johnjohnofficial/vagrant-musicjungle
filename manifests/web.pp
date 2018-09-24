exec { "apt-update":
	command => "apt-get update",
	path => "/usr/bin"
}

package { ["openjdk-7-jre", "tomcat7", "mysql-server"]:
	ensure => installed,
	require => Exec["apt-update"]
}

service { "tomcat7":
	ensure => running,
	enable => true,
	hasstatus => true,
	hasrestart => true,
	require => Package["tomcat7"]
}

service { "mysql":
	ensure => running,
	enable => true,
	hasstatus => true,
	hasrestart => true,
	require => Package["mysql-server"]
}

file { "/var/lib/tomcat7/webapps/vraptor-musicjungle.war":
	source => "/vagrant/manifests/vraptor-musicjungle.war",
	owner => "tomcat7",
	group => "tomcat7",
	mode => 0644,
	require => Package["tomcat7"],
	notify => Service["tomcat7"]
}

exec { "musicjungle":
	command => "mysqladmin -uroot create musicjungle",
	path => "/usr/bin",
	unless => "mysql -uroot musicjungle",
	require => Service["mysql"]
}

exec { "credencial":
	command => "mysql -uroot -e \"GRANT ALL PRIVILEGES ON * TO 'musicjungle'@'%' IDENTIFIED BY '123';\" musicjungle",
	unless => "mysql -u musicjungle -p123 musicjungle",
	path => "/usr/bin",
	require => Exec["musicjungle"]
}

file_line { "production":
    file => "/etc/default/tomcat7",
    line => "JAVA_OPTS=\"\$JAVA_OPTS -Dbr.com.caelum.vraptor.environment=production\"",
    require => Package["tomcat7"],
    notify => Service["tomcat7"]
}

define file_line($file, $line) {
    exec { "/bin/echo '${line}' >> '${file}'":
        unless => "/bin/grep -qFx '${line}' '${file}'"
    }
}
