﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Security.Principal;
using NReco;
using System.Web.Security;

namespace NReco.Web.Site.Security {

	/// <summary>
	/// Context user key value provider.
	/// </summary>
	public class UserKeyProvider : IProvider<object,object> {

		public object AnonymousKey { get; set; }
		public bool UseContextUserName { get; set; }

		public UserKeyProvider() {
			UseContextUserName = false;
		}

		public object Provide(object context) {
			string username = null;
			if (UseContextUserName) {
				if (context is IPrincipal)
					username = ((IPrincipal)context).Identity.Name;
				else if (context is string)
					username = (string)context;
			}
			var user = username!=null ? Membership.GetUser(username) : Membership.GetUser();
			return user != null ? user.ProviderUserKey : AnonymousKey;
		}

	}


}
