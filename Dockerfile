FROM eirinicf/scf-api-group:e6eaf22bc669b4da2c8abd18028cf84d24e0e492

COPY lib/cloud_controller/opi/env_hash.rb /var/vcap/packages/cloud_controller_ng/cloud_controller_ng/lib/cloud_controller/opi/
COPY lib/cloud_controller/opi/stager_client.rb /var/vcap/packages/cloud_controller_ng/cloud_controller_ng/lib/cloud_controller/opi/

ENTRYPOINT ["/usr/bin/dumb-init", "/opt/fissile/run.sh"]
