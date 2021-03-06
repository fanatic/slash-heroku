class AdminConstraint
  GITHUB_ADMIN_LOGINS = ENV.fetch("GITHUB_ADMIN_LOGINS", "").split(",").freeze

  def matches?(request)
    return false unless request.session[:user_id]
    u = User.find(request.session[:user_id])
    return false unless u.github_login.present?
    GITHUB_ADMIN_LOGINS.include?(u.github_login)
  end
end
