require File.dirname(__FILE__)+'/cron_helper'
require 'openssl'

# Create private and public keys for users, for ActivePub, etc.


for p in Participant.all

  if p.private_key.to_s == ''
    puts "#{p.id} : #{p.name} : #{p.account_uniq}"
    
    rsa_key = OpenSSL::PKey::RSA.new(2048)
    private_key = rsa_key.to_pem
    public_key = rsa_key.public_key.to_pem

    puts " - #{public_key}"
    
    p.private_key = private_key
    p.public_key = public_key
    p.save!

    puts "  - updated"
  end

end