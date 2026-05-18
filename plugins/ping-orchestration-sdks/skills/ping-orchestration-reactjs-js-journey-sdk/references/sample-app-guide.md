# Sample App Steps (Steps 12–14)

These steps are only needed when the user chose **Sample Application** mode, or explicitly requests
a profile page, navbar, or full router wiring.

---

## Step 12 — Create a User Profile View

Create `profile.jsx` — a protected view that fetches and displays user information from the OIDC `userinfo` endpoint. Optionally includes an edit modal with Save/Cancel.

Key implementation:
- Use `oidcClient.user.info()` to fetch the full user profile from AIC
- Display all returned claims (sub, name, email, phone, address, etc.)
- Provide an "Edit Profile" button that opens a modal with form fields
- The modal should have **Save** and **Cancel** buttons
- Save updates the local display state (for server-side persistence, connect to the AIC IDM managed objects API)

```jsx
import { useContext, useState, useEffect } from 'react';
import { OidcContext } from '../context/oidc.context';

export default function Profile() {
  const [{ oidcClient }] = useContext(OidcContext);
  const [profile, setProfile] = useState(null);
  const [showEditModal, setShowEditModal] = useState(false);

  useEffect(() => {
    async function fetchProfile() {
      const userInfo = await oidcClient.user.info();
      if (!('error' in userInfo)) setProfile(userInfo);
    }
    fetchProfile();
  }, [oidcClient]);

  // Render profile fields and edit modal...
}
```

**Common userinfo claims from AIC:**

| Claim | Description |
|-------|-------------|
| `sub` | Subject identifier (user ID) |
| `name` | Full display name |
| `given_name` | First name |
| `family_name` | Last name |
| `email` | Email address |
| `email_verified` | Whether email has been verified |
| `phone_number` | Phone number |
| `address` | Address object (`formatted`, `street_address`, etc.) |
| `updated_at` | Unix timestamp of last profile update |

> **Note on server-side profile updates:** To persist profile edits to AIC, call the AIC IDM managed
> objects REST API (`/openidm/managed/alpha_user/<userId>`) with the user's access token. This requires
> the OAuth client to have `fr:idm:*` scope or equivalent. For a sample app, updating local display
> state is sufficient to demonstrate the pattern.

---

## Step 13 — Add Navigation and Styling

For a complete sample app, create:

1. **A Navbar component** (`client/components/navbar.jsx`) — Sticky top navigation with links to the main views (Home/Gallery, Profile) and a logout button. Show the authenticated user's name.

2. **A CSS stylesheet** (`client/styles.css`) — Import in `index.jsx`. Should include at minimum:
   - Global reset and base typography
   - Form field styling (inputs, labels, selects, buttons)
   - Glass-morphism or card-based layout for auth forms
   - Navigation bar styles
   - Image grid / card grid for content pages
   - Modal/overlay styles for edit dialogs
   - Responsive breakpoints for mobile
   - Loading spinners and status indicators

3. **A themed Home view** — Replace the basic home template with content relevant to the user's request. The home view should show different content for authenticated vs unauthenticated users.

```jsx
// Example Navbar pattern
import { useContext } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { OidcContext } from '../context/oidc.context';

export default function Navbar() {
  const [{ username }] = useContext(OidcContext);
  return (
    <nav className="navbar">
      <Link to="/">Home</Link>
      <Link to="/profile">My Profile</Link>
      <span>{username}</span>
      <Link to="/logout">Logout</Link>
    </nav>
  );
}
```

> **Agent instruction for sample apps:** When the user describes a theme or purpose (e.g., "space
> images", "recipe app", "fitness tracker"), create the Home view content, styling, and any additional
> views to match that theme. Always include: a visually distinct login/register page; a navbar with
> logout and profile links (when authenticated); a home page with themed content (authenticated) and
> a call-to-action (unauthenticated); a profile page behind a protected route.

---

## Step 14 — Wire the Router with All Views

Update `router.jsx` to include routes for all views including the profile page:

```jsx
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { ProtectedRoute } from './components/utilities/route';
import Home from './views/home';
import Login from './views/login';
import Logout from './views/logout';
import Register from './views/register';
import Profile from './views/profile';

export default function Router() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/login" element={<Login />} />
        <Route path="/register" element={<Register />} />
        <Route path="/logout" element={<Logout />} />
        <Route
          path="/profile"
          element={
            <ProtectedRoute>
              <Profile />
            </ProtectedRoute>
          }
        />
      </Routes>
    </BrowserRouter>
  );
}
```
