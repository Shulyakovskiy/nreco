﻿#region License
/*
 * NReco library (http://code.google.com/p/nreco/)
 * Copyright 2008 Vitaliy Fedorchenko
 * Distributed under the LGPL licence
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
#endregion

using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Web;
using System.Web.UI;
using System.Web.Routing;

namespace NReco.Web.Site {
	
	public class RoutePage : Page, IRouteAware {
		public RoutePage() { }

		public RequestContext RouteContext { get; set; }

		public IDictionary<string,object> PageContext {
			get {
				if (RouteContext!=null)
					return RouteContext.RouteData.Values;
				return new Dictionary<string, object>();
			}
		}
	}
}