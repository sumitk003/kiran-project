namespace :credentials do
  desc "Encrypt sensitive tokens for all accounts using ENV credentials"
  task :encrypt_token => :environment do
    require 'active_support'
    require 'active_support/message_encryptor'
    require 'active_support/key_generator'

    PROD_SECRET_KEY = "a50eb7a49a09f3f53db28382cf691ca5fa2f17a9c6d83cf08111e14308a5321af6fccf1d6a697d2d8ccd2ba48a228bfc148325e9670b2a02a16947412496e24d"
    PROD_SALT = "218a797119fe657c04a5eb149953db90"
    ENV_SECRET_KEY = "ab143d4b02a5a1de9f2a7d1e6e12b838bcaf0764de18e839f68dba9f7d9f98a711e0062ba1d011b9e2932b641a151ff212032873d77a22bc4a0df5f4eeac719b"
    ENV_SALT = "c84d2f9b828e0f82dd62da40bba58c778c68bd20e4c80d871d56288f407dfd02"

    accounts = Account.all

    accounts.each do |account|
    
      decrypted_values = decrypt_values(account, PROD_SECRET_KEY, PROD_SALT)
      encrypted_values = encrypt_values_using_env_creds(decrypted_values, ENV_SECRET_KEY, ENV_SALT)
      next if encrypted_values.empty?
     
      ActiveRecord::Base.transaction do
        account.update!(encrypted_values)
        puts "Updated Account ID #{account.id}"
      end
    end
  end

  def decrypt_value(value, key_base, salt)
    
    return nil if value.blank?

    key = ActiveSupport::KeyGenerator.new(key_base).generate_key(salt, 32)
    crypt = ActiveSupport::MessageEncryptor.new(key)
    crypt.decrypt_and_verify(value)
  rescue => e
    puts "Failed to decrypt value: #{e.message}"
    nil
  end

  def decrypt_values(account, key_base, salt)
    
    
    {
      griffin_property_encrypted_password: decrypt_value(account.griffin_property_encrypted_password, key_base, salt),
      encrypted_griffin_property_com_au_api_token: decrypt_value(account.encrypted_griffin_property_com_au_api_token, key_base, salt),
      azure_encrypted_client_secret: decrypt_value(account.azure_encrypted_client_secret, key_base, salt),
      domain_com_au_encrypted_access_token: decrypt_value(account.domain_com_au_encrypted_access_token, key_base, salt),
      rea_encrypted_client_secret: decrypt_value(account.rea_encrypted_client_secret, key_base, salt),
      domain_com_au_encrypted_client_secret: decrypt_value(account.domain_com_au_encrypted_client_secret, key_base, salt),
      domain_com_au_encrypted_authorization_code: decrypt_value(account.domain_com_au_encrypted_authorization_code, key_base, salt),
      domain_com_au_encrypted_refresh_token: decrypt_value(account.domain_com_au_encrypted_refresh_token, key_base, salt)
    }.compact
  end

  def encrypt_values_using_env_creds(values_hash, key_base, salt)
    return {} if values_hash.empty?

    key = ActiveSupport::KeyGenerator.new(key_base).generate_key(salt, 32)
    crypt = ActiveSupport::MessageEncryptor.new(key, cipher: 'aes-256-gcm')

    values_hash.each_with_object({}) do |(field, value), result|
      result[field] = crypt.encrypt_and_sign(value) if value.present?
    end
  end
end
