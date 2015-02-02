Chef::Log.info("DEPLOY: Before restart")

node[:deploy].each do |application, deploy|
  
  opsworks_deploy_dir do
    user deploy[:user]
    group deploy[:group]
    path deploy[:deploy_to]
  end

  opsworks_deploy do
    deploy_data deploy
    app application
  end
  
  script "install_composer" do
    Chef::Log.info("DEPLOY: Shutting down the current running")
    interpreter "bash"
    user "root"
    cwd "#{deploy[:deploy_to]}/current"
    code <<-EOH
        curl -XPOST "http://localhost:8080/admin/shutdown" > /var/log/app.log 2>&1 || : 
		RETVAL=$?
		if [ $RETVAL -eq 0 ]
		then
			echo "Service stopped"
		else
			echo "Can not stop the service"
		fi
		exit 0
    EOH
  end
  
  script "runjar" do
    Chef::Log.info("DEPLOY: Running the deployed")
    interpreter "bash"
    user "root"
    cwd "#{deploy[:deploy_to]}/current"
    code <<-EOH
        java -jar *.jar > /var/log/app.log 2>&1 &
    EOH
  end
end

