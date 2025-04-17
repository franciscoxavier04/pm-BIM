# frozen_string_literal: true

class RemoveLdapTlsSetting < ActiveRecord::Migration[7.1]
  def up
    execute "DELETE FROM settings WHERE name = 'ldap_tls_options'"
  end

  def down
    # Nothing to do
  end
end
