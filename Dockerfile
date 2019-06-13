FROM eirinicf/scf-api-group:e6eaf22bc669b4da2c8abd18028cf84d24e0e492

COPY lib/cloud_controller/opi/ /var/vcap/packages/cloud_controller_ng/cloud_controller_ng/lib/cloud_controller/opi/
COPY lib/cloud_controller/diego/reporters/instances_stats_reporter.rb /var/vcap/packages/cloud_controller_ng/cloud_controller_ng/lib/cloud_controller/diego/reporters/

ENTRYPOINT ["/usr/bin/dumb-init", "/opt/fissile/run.sh"]
