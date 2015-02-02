node[:deploy].each do |application, deploy|
  
  opsworks_deploy_dir 'SpringBoot: Preparing the deployment dir' do
    user deploy[:user]
    group deploy[:group]
    path deploy[:deploy_to]
  end

  opsworks_deploy 'SpringBoot: Deploying the app' do
    deploy_data deploy
    app application
  end
  
  bash 'SpringBoot: Shutting down the current running' do
    user 'root'
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
  
  bash 'SpringBoot: Running the deployed' do
    user "root"
    cwd "#{deploy[:deploy_to]}/current"
    code <<-EOH
        java -jar *.jar > /var/log/app.log 2>&1 &
    EOH
  end
  
end



