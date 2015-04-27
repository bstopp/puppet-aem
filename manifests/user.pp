class adobe_experience_manager::user {

  if $adobe_experience_manager::manage_group {
    group { $adobe_experience_manager::group:
      ensure => present,
    }
  }

  if $adobe_experience_manager::manage_user {
    user { $adobe_experience_manager::user:
      ensure => present,
      gid    => $adobe_experience_manager::group,
    }
  }

}