#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class RenamePortugueseLocale < ActiveRecord::Migration[7.1]
  def up
    execute "UPDATE users SET language = 'pt-BR' WHERE language = 'pt'"
    execute "UPDATE settings SET value = 'pt-BR' WHERE name = 'default_language' AND value = 'pt'"
    modify_available_languages!("pt", "pt-BR")
  end

  def down
    execute "UPDATE users SET language = 'pt' WHERE language = 'pt-BR'"
    execute "UPDATE settings SET value = 'pt' WHERE name = 'default_language' AND value = 'pt-BR'"
    modify_available_languages!("pt-BR", "pt")
  end

  private

  def modify_available_languages!(from, to)
    languages = Setting.available_languages
    if languages.include?(from)
      languages << to
      languages.delete(from)
      Setting.available_languages = languages
    end
  end
end
