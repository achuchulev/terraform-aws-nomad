describe command('terraform output') do
  its('stdout') { should include "client_private_ips" }
  its('stderr') { should include '' }
  its('exit_status') { should eq 0 }
end
describe command('terraform output') do
  its('stdout') { should include "server_private_ips" }
  its('stderr') { should include '' }
  its('exit_status') { should eq 0 }
end
describe command('terraform output') do
  its('stdout') { should include "frontend_public_ip" }
  its('stderr') { should include '' }
  its('exit_status') { should eq 0 }
end