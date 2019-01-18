# NAME

ardoman - Arhimed's Docker Manager

# VERSION

This documentation refers to ardoman version 0.0.1.

# USAGE

\# Brief working invocation example(s) here showing the most common usage(s)
\# This section will be as far as many users ever read,
\# so make it as educational and exemplary as possible.

    PERL5LIB=lib bin/ardoman.pl \
        --host localhost:2375 \
        --confdir config \
        --save \
        --show \
        --endpoint localhost \
        --application tomcat \
        --name tomcat \
        --image tomcat \
        --ports 8080:8080 \
        --check_proc java \
        --check_delay 5 \
        --check_url http://127.0.0.1:8080/ \
        --action deploy

    PERL5LIB=lib bin/ardoman.pl \
        --confdir config \
        --endpoint localhost \
        --application tomcat \
        --name tomcat1 \
        --ports 8081:8080 \
        --check_url http://127.0.0.1:8081/ \
        --action deploy

# REQUIRED ARGUMENTS

### Minimal required arguments.

The one of this combination is required.

    --host=<host> - explicit host (host ip/url with port) to EP.

    --confdir=<config> --endpoint=<EP> - name of previously saved EP config.

    DOCKER_HOST=<host> - environment variable.

### Other cases

    --action=deploy | --action=create - requires option '--image'

Note also you can specify pair of '--confdir' and '--application' to get 
previously saved '--image' option.

### For any other action

    --action=<action> - requires '--name' or '--id'

Note also you can specify pair of '--confdir' and '--application' to get
previously saved '--name' (not --id) option.

# OPTIONS

Common options like:

           ardoman.pl --help
           ardoman.pl --man
           ardoman.pl --usage
           ardoman.pl --version

are supported by Getopt::Euclid module. Thanks a lot.

- --action \[=\] &lt;action> | --Action \[=\] &lt;action>

    Action what need to do with application. Valid actions are:
        deploy
        undeploy
        create
        remove
        start
        stop
        get
        check

    Note configuration related commands ('--save', '--purge') do not affect 
    '--action' behavior and do not depend on '--action'.

- --confdir \[=\] &lt;root\_config\_dir>

    Directory where is configuration files are located.
    Contains two directories 'endpoints' and 'applications' for different types
    of configs.

- --show

    Command to show configurations before save/purge it and connect to endpoint.

- --save

    Command to save endpoint's and application's configurations into database.

- --purge

    Command to purge both configurations after use (or may be after save also).

- --endpoint \[=\] &lt;name\_EP\_config>

    Name of connection setting to docker endpoint.
    Incorporates such option as:
        host
        tls\_verify
        ca\_file
        cert\_file
        key\_file
    This also name for operating with saved configuration: save, load, purge.
    So it must be uniq, otherwise in save case endpoint options 
    will be overwritten.

- --host \[=\] &lt;host\_and\_port>

    Daemon socket(s) to connect to.
    Default to $ENV{DOCKER\_HOST}

- --tls\_verify

    Use TLS and verify the remote.
    Default to $ENV{DOCKER\_TLS\_VERIFY}

- --ca\_file \[=\] &lt;path\_to\_ca\_file>

    Trust certs signed only by this CA.
    Path to ca cert file, default to $ENV{DOCKER\_CERT\_PATH}/ca.pem

- --cert\_file \[=\] &lt;path\_to\_cert\_file>

    Path to TLS certificate file.
    Path to client cert file, default to $ENV{DOCKER\_CERT\_PATH}/cert.pem

- --key\_file \[=\] &lt;path\_to\_key\_file>

    Path to TLS key file.
    Path to client key file, default to $ENV{DOCKER\_CERT\_PATH}/key.pem

- --application \[=\] &lt;app\_name> | --Application \[=\] &lt;app\_name>

    Name of aggregate of container related options.
    With this name those option will be load/save/purge with corresponding 
    configuration related commands.

    Note all application related parameters have a sibling with
    capitalized first letter. 

- --name \[=\] &lt;container\_name> | --Name \[=\] &lt;container\_name>

    Assign the specified name to the container in case 'create' or 'deploy'.
    Or search container by name for other cases.

- --id \[=\] &lt;id> | --Id \[=\] &lt;id>

    A container's ID. Uses with commands except 'create' or 'deploy'.
    In this case argument '--name' may be omitted.

- --image \[=\] &lt;image\_name> | --Image \[=\] &lt;image\_name>

    The name of the image to use when creating the container.

    Note for commands 'create' or 'deploy' this option is necessary.

- --ports \[=\] &lt;ports> | --Ports \[=\] &lt;ports>

    Either specify both ports (HOST:CONTAINER), or just the container port,
    or maximum form (HOST\_IP:HOST\_PORT:CONTAINER\_PORT).

    Exapmle:
        - "3000"
        - "8000:8000/tcp"
        - "127.0.0.1:8001:8001"

    You can use more then one port bindings, to do this just specify --ports as
    many times as you need:

        --ports '5556:5556' --ports '7001:7001'

- --env \[=\] &lt;env> | --Env \[=\] &lt;env>

    A list of environment variables to set inside the container 
    in the form "VAR=value", ...

    This may be specified several times for different variables.

        --env a=b --env c=d

- --cmd \[=\] &lt;cmd>... | --Cmd \[=\] &lt;cmd>...

    Command to run specified as a string or an array of strings.
    This argument can use only one time, but it accepts many values.

        PERL5LIB=lib bin/ardoman.pl \
            --confdir=config \
            --endpoint=localhost \
            --host=localhost:2375 \
            --show \
            --action=deploy \
            --name=nc \
            --image='subfuzion/netcat' \
            --cmd '-l' '0.0.0.0' '7777' \
            --ports '5555:5555'

- --check\_proc \[=\] &lt;process\_re> | --Check\_proc \[=\] &lt;process\_re>

    Pattern of process to find it after start application. 
    This may be specified several times for different variables.
    If many processes specified all of these must be run at check time.

- --check\_url \[=\] &lt;fq\_url> | --Check\_url \[=\] &lt;fq\_url>

    After deploy you can check if application response via HTTP.
    To do this you must specify full qualified URL. Verification 
    is performed using the module LWP::UserAgent but without any custom 
    settings. Application must return non-error response (neither 4xx 
    nor 5xx).

- --check\_delay \[=\] &lt;seconds> | --Check\_delay \[=\] &lt;seconds>

    Since the processes need time to start, we will wait a little.
    The value must contain an integer number of seconds.

- --debug

    This argument makes program generate stack backtraces
    when something went wrong.

# DESCRIPTION

This application is designed to deploy various docker applications 
on different endpoints. It uses command line interface to get required 
parameters and directives what to do.

# Examples

## Deploy/undeploy 'hello-world' with minimal options

    PERL5LIB=lib bin/ardoman.pl \
        --host=localhost:2375 \
        --image='tutum/hello-world' \
        --action=deploy

Which is absolutely pointless because we have not taken care of the ports.
Program will print us new docker container ID, like

    940e70618d095ffb12ec142fbafe6d87c8670ff93c5a534747f3fcfc38513605

which we can to manipulate container

    PERL5LIB=lib bin/ardoman.pl \
        --host=localhost:2375 \
        --id=940e70618d095ffb12ec142fbafe6d87c8670ff93c5a534747f3fcfc38513605 \
        --action=stop

This returns the same Id again (as sign of successful completion)

By the way, new container got automatic name (in my case 'adoring\_khorana')

    PERL5LIB=lib bin/ardoman.pl \
        --host=localhost:2375 \
        --name='adoring_khorana' \
        --action=remove

And again we will see Id of container as sign of success.

## Deploy/undeploy 'netcat' with 'cmd' option

    PERL5LIB=lib bin/ardoman.pl \
        --host=localhost:2375 \
        --confdir=config \
        --show \
        --endpoint=localhost \
        --name=nc \
        --image='subfuzion/netcat' \
        --cmd '-l' '0.0.0.0' '5555' \
        --ports 'localhost:5555:5555' \
        --action=deploy

You can use for undeploy the same arguments - extra will be ignored.

    PERL5LIB=lib bin/ardoman.pl \
        --host=localhost:2375 \
        --confdir=config \
        --show \
        --endpoint=localhost \
        --name=nc \
        --image='subfuzion/netcat' \
        --cmd '-l' '0.0.0.0' '5555' \
        --ports 'localhost:5555:5555' \
        --action=undeploy

## Deploy 'tomcat' with 'check\_url' and 'ckeck\_proc' options

You can save endpoint parameters to config, then just specify '--endpoint'

    PERL5LIB=lib bin/ardoman.pl \
        --host localhost:2375 \
        --confdir config \
        --endpoint farfar \
        --show \
        --save

Application setting may be saved too:

    PERL5LIB=lib bin/ardoman.pl \
        --confdir config \
        --endpoint farfar \
        --application tomcat \
        --save \
        --name tomcat \
        --image tomcat \
        --ports 8080:8080 \
        --check_proc java \
        --check_url http://127.0.0.1:8080/ \
        --action deploy

and then use for further operations (like undeploy).
Note that 'Id' won't save in Application configuration, just 'name'

    PERL5LIB=lib bin/ardoman.pl \
        --confdir config \
        --endpoint farfar \
        --application tomcat \
        --action undeploy

## Deploy/undeploy 'glassfish' with separate steps

Create configurations, and save them:

    PERL5LIB=lib bin/ardoman.pl \
        --host=localhost:2375 \
        --confdir=config \
        --endpoint=glassfish_EP \
        --application=glassfish \
        --name=glassfish \
        --show \
        --save

Create container, pass almost all options:

    PERL5LIB=lib bin/ardoman.pl \
        --confdir=config \
        --endpoint=glassfish_EP \
        --application=glassfish \
        --image='glassfish' \
        --ports '4848:4848' \
        --ports '8080:8080' \
        --ports '8181:8181' \
        --action=create

Check it has created:

    PERL5LIB=lib bin/ardoman.pl --confdir=config --endpoint=glassfish_EP \
        --application=glassfish --action=get

Then start it:

    PERL5LIB=lib bin/ardoman.pl --confdir=config --endpoint=glassfish_EP \
        --application=glassfish --action=start

And check processes and URLs:

    PERL5LIB=lib bin/ardoman.pl \
        --confdir=config \
        --endpoint=glassfish_EP \
        --application=glassfish \
        --check_proc glassfish.jar \
        --check_proc 'appserver-cli.jar start-domain' \
        --check_url http://127.0.0.1:8080/ \
        --check_url http://127.0.0.1:4848/ \
        --action=check

Now can stop container:

    PERL5LIB=lib bin/ardoman.pl --confdir=config --endpoint=glassfish_EP \
        --application=glassfish --action=stop

Check it is still available (and can be started again)

    PERL5LIB=lib bin/ardoman.pl --confdir=config --endpoint=glassfish_EP \
        --application=glassfish --action=get

Remove container:

    PERL5LIB=lib bin/ardoman.pl --confdir=config --endpoint=glassfish_EP \
        --application=glassfish --action=remove

And check that it is no longer available.

    PERL5LIB=lib bin/ardoman.pl --confdir=config --endpoint=glassfish_EP \
        --application=glassfish --action=get

## Create Weblogic with 'env' and fail check\_url as expected

Try to deploy WebLogicServer.

    DOCKER_HOST=127.0.0.1:2375 PERL5LIB=lib bin/ardoman.pl \
        --debug
        --name=wl1 \
        --image='alanpeng/oracle-weblogic11g' \
        --ports '8001:5556' \
        --ports '7001:7001' \
        --check_proc java \
        --check_url http://127.0.0.1:7001/ \
        --action=deploy

Will get "500 Status read failed: Connection reset by peer" message.
Due to '--debug' argument find that failure was check stage.

Using 'docker logs wl' figure out that password required. So set '--env'
and try to run again.

    DOCKER_HOST=127.0.0.1:2375 PERL5LIB=lib bin/ardoman.pl \
        --debug
        --name=wl2 \
        --image='alanpeng/oracle-weblogic11g' \
        --ports '8002:5556' \
        --ports '7002:7001' \
        --check_proc java \
        --check_url http://127.0.0.1:7002/ \
        --env base_domain_default_password=123AAA456zzz \
        --action=deploy

Will get "500 Status read failed: Connection reset by peer" message.
But this not what we expect. It is because the server does not have 
time to start. Add '--check\_delay=30'

    DOCKER_HOST=127.0.0.1:2375 PERL5LIB=lib bin/ardoman.pl \
        --debug
        --name=wl3 \
        --image='alanpeng/oracle-weblogic11g' \
        --ports '8003:5556' \
        --ports '7003:7001' \
        --check_proc java \
        --check_url http://127.0.0.1:7003/ \
        --env base_domain_default_password=123AAA456zzz \
        --check_delay=30 \
        --action=deploy

We'll get HTTP/1.1 404 Not Found which is not good.
But this is beyond the scope of the task.

# EXIT STATUS

Returns zero exit status on success.

In case failure returns non zero exit status (255 actually).

This may mean such reasons (but not limited to):

    Wrong arguments
    Required argument missed
    Config directories are not writable
    Write config failure (open for write, print, close)
    Can not connect to endpoint
    Image not found
    Ports are busy
    Name conflicts or short or wrong
    Check not started container
    Remove started container
    Container not found by Id or Name
    Check failed (URL does not response, process does not exist)

# DIAGNOSTICS

For unit test, use:

    PERL5LIB=lib prove -r -v

or one find of tests only

    PERL5LIB=lib prove -v t/unit 
    PERL5LIB=lib prove -v t/func

In the case of debugging, you can specify parameter --debug that will enable
$Carp::Verbose. This variable makes program generate stack backtraces.

# CONFIGURATION

Since it was necessary to write quickly and briefly, I chose to save the
configuration in files in the "JSON" format. I also decided that it would be
convenient to separate the configuration of the endpoint and the application.
This allows us to deploy one application to multiple endpoints and vice versa
to deploy different applications to one endpoint.

Therefore, the argument "--confdir" to the program is the directory where the
configuration files will be located.  For applications in the "applications"
folder, for endpoints in the "endpoints" folder. Work with the configuration
is carried out regardless of the action specified by the argument "action".
When specifying the argument to the program "--confdir", an automatic loading
of the saved configurations from the corresponding files occurs. However,
command line agruments of course takes precedence and overwrite data from
configurations. 

When specifying the "--save" argument after connecting the saved configuration
with the command line arguments, the program saves the data in a file.

If the "purge" argument is also specified (or only), configuration files are
deleted at the last stage, before exiting the program.

# ENVIRONMENT

You can also use environment variables to specify some parameters.
Eixo::Docker::Api supports these environment variables:

    DOCKER_HOST
    DOCKER_TLS_VERIFY
    DOCKER_CERT_PATH

So you can even ommit mandatory parameter 'host':

    PERL5LIB=lib DOCKER_HOST=localhost:2375 bin/ardoman.pl \
        --name hello --action check

# DEPENDENCIES

This application uses these third party CPAN modules:

    Eixo::Docker::Api
    Clone
    Readonly
    List::Util
    Eixo::Docker::Api
    LWP::UserAgent
    File::Path
    File::Spec
    File::Slurp
    JSON

Tests also requires additional test-related modules:

    Test::More
    Test::Exception
    Test::VirtualModule

Also be aware that program do not autoload images for containers. So before
run sure that images are available. For correct run system tests you need 
download this image before run system tests: tutum/hello-world

For correct run examples described in this documentation you should load these
docker's images:

    tutum/hello-world
    tomcat
    glassfish
    alanpeng/oracle-weblogic11g
    subfuzion/netcat

# INCOMPATIBILITIES

Not found yet.

# BUGS AND LIMITATIONS

There are no known bugs in this module.
Please report problems to Timothy Khalatskiy, <arhimed2t@gmail.com>
Patches are welcome.

# AUTHOR

Timothy Khalatskiy, <arhimed2t@gmail.com>

# LICENSE AND COPYRIGHT

Copyright (c) 2019 Timothy Khalatskiy (<arhimed2t@gmail.com>). All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
