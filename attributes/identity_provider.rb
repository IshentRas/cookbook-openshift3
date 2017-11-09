# `oauth_Identity` saved for backward compatibility, please use `oauth_Identities` instead
default['cookbook-openshift3']['oauth_Identity'] = 'HTPasswdPasswordIdentityProvider'
default['cookbook-openshift3']['oauth_Identities'] = [node['cookbook-openshift3']['oauth_Identity']]

# See https://github.com/IshentRas/cookbook-openshift3/issues/115 - if you want ca/certFile/keyFile as per below, you need to add it into your config.
# default['cookbook-openshift3']['openshift_master_identity_provider']['BasicAuthPasswordIdentityProvider'] = { 'name' => 'basic_auth', 'login' => true, 'challenge' => true, 'kind' => 'BasicAuthPasswordIdentityProvider', 'url' => 'https://www.example.com/remote-idp', 'ca' => '', 'certFile' => '', 'keyFile' => '' }
default['cookbook-openshift3']['openshift_master_identity_provider']['BasicAuthPasswordIdentityProvider'] = { 'name' => 'basic_auth', 'login' => true, 'challenge' => true, 'kind' => 'BasicAuthPasswordIdentityProvider', 'url' => 'https://www.example.com/remote-idp' }

default['cookbook-openshift3']['openshift_master_identity_provider']['GitHubIdentityProvider'] = { 'name' => 'github_auth', 'login' => true, 'challenge' => false, 'kind' => 'GitHubIdentityProvider', 'clientID' => 'github_client_id', 'clientSecret' => 'github_client_secret' }

default['cookbook-openshift3']['openshift_master_identity_provider']['GoogleIdentityProvider'] = { 'name' => 'google_auth', 'login' => true, 'challenge' => false, 'kind' => 'GoogleIdentityProvider', 'clientID' => 'google_client_id', 'clientSecret' => 'google_client_secret' }

default['cookbook-openshift3']['openshift_master_identity_provider']['HTPasswdPasswordIdentityProvider'] = { 'name' => 'htpasswd_auth', 'login' => true, 'challenge' => true, 'kind' => 'HTPasswdPasswordIdentityProvider', 'filename' => "#{default['cookbook-openshift3']['openshift_common_master_dir']}/openshift-passwd" }

default['cookbook-openshift3']['openshift_master_identity_provider']['LDAPPasswordIdentityProvider'] = { 'name' => 'ldap_identity1', 'login' => true, 'challenge' => true, 'kind' => 'LDAPPasswordIdentityProvider', 'ldap_server' => 'ldap1.domain.local', 'ldap_bind_dn' => '', 'ldap_bind_password' => '', 'ldap_insecure' => true, 'ldap_base_ou' => 'OU=people,DC=domain,DC=local', 'ldap_preferred_username' => 'uid' }

# See https://github.com/IshentRas/cookbook-openshift3/issues/115 - if you want userInfo, preferred_username, name, email as per below, you need to add it into your config.
# default['cookbook-openshift3']['openshift_master_identity_provider']['OpenIDIdentityProvider'] = { 'name' => 'openid_auth', 'login' => true, 'challenge' => true, 'kind' => 'OpenIDIdentityProvider', 'clientID' => 'openid_client_id', 'clientSecret' => 'openid_client_secret', 'claims' => { 'id' => 'sub', 'preferredUsername' => 'preferred_username', 'name' => 'name', 'email' => 'email' }, 'urls' => { 'authorize' => 'https://myidp.example.com/oauth2/authorize', 'token' => 'https://myidp.example.com/oauth2/token', 'userInfo' => 'https://myidp.example.com/oauth2/userinfo' } }
default['cookbook-openshift3']['openshift_master_identity_provider']['OpenIDIdentityProvider'] = { 'name' => 'openid_auth', 'login' => true, 'challenge' => true, 'kind' => 'OpenIDIdentityProvider', 'clientID' => 'openid_client_id', 'clientSecret' => 'openid_client_secret', 'claims' => { 'id' => 'sub' }, 'urls' => { 'authorize' => 'https://myidp.example.com/oauth2/authorize', 'token' => 'https://myidp.example.com/oauth2/token' } }

# See https://github.com/IshentRas/cookbook-openshift3/issues/115 - if you want clientCA as per below, you need to add it into your config.
# default['cookbook-openshift3']['openshift_master_identity_provider']['RequestHeaderIdentityProvider'] = { 'name' => 'header_provider_identify', 'login' => false, 'challenge' => false, 'kind' => 'RequestHeaderIdentityProvider', 'headers' => %w(X-Remote-User SSO-User), 'clientCA' => "#{default['cookbook-openshift3']['openshift_common_master_dir']}/master/ca.crt" }
default['cookbook-openshift3']['openshift_master_identity_provider']['RequestHeaderIdentityProvider'] = { 'name' => 'header_provider_identify', 'login' => false, 'challenge' => false, 'kind' => 'RequestHeaderIdentityProvider', 'headers' => %w(X-Remote-User SSO-User) }

default['cookbook-openshift3']['openshift_master_htpasswd'] = "#{node['cookbook-openshift3']['openshift_common_master_dir']}/openshift-passwd"

default['cookbook-openshift3']['openshift_master_htpasswd_users'] = []
