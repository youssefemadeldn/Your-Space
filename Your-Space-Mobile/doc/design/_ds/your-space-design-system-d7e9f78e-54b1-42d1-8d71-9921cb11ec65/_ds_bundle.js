/* @ds-bundle: {"format":4,"namespace":"YourSpaceDesignSystem_d7e9f7","components":[{"name":"Avatar","sourcePath":"components/core/Avatar.jsx"},{"name":"AvatarStack","sourcePath":"components/core/Avatar.jsx"},{"name":"Badge","sourcePath":"components/core/Badge.jsx"},{"name":"Button","sourcePath":"components/core/Button.jsx"},{"name":"Chip","sourcePath":"components/core/Chip.jsx"},{"name":"IconButton","sourcePath":"components/core/IconButton.jsx"},{"name":"Card","sourcePath":"components/display/Card.jsx"},{"name":"EmptyState","sourcePath":"components/display/EmptyState.jsx"},{"name":"ListTile","sourcePath":"components/display/ListTile.jsx"},{"name":"Dialog","sourcePath":"components/feedback/Dialog.jsx"},{"name":"Snackbar","sourcePath":"components/feedback/Snackbar.jsx"},{"name":"Checkbox","sourcePath":"components/forms/Checkbox.jsx"},{"name":"Input","sourcePath":"components/forms/Input.jsx"},{"name":"Radio","sourcePath":"components/forms/Radio.jsx"},{"name":"Select","sourcePath":"components/forms/Select.jsx"},{"name":"Switch","sourcePath":"components/forms/Switch.jsx"},{"name":"AppBar","sourcePath":"components/navigation/AppBar.jsx"},{"name":"BottomNav","sourcePath":"components/navigation/BottomNav.jsx"},{"name":"Tabs","sourcePath":"components/navigation/Tabs.jsx"}],"sourceHashes":{"components/core/Avatar.jsx":"e1b8a936681a","components/core/Badge.jsx":"10b9da19dd5a","components/core/Button.jsx":"72549f0b288f","components/core/Chip.jsx":"b067b87a0b3b","components/core/IconButton.jsx":"f910998d2f89","components/display/Card.jsx":"44b857e4c3a2","components/display/EmptyState.jsx":"e13622c7669b","components/display/ListTile.jsx":"4fe4e23dd7bf","components/feedback/Dialog.jsx":"25a851dea0eb","components/feedback/Snackbar.jsx":"9c2d5f207b2f","components/forms/Checkbox.jsx":"7b980863a63b","components/forms/Input.jsx":"f8679cc586c7","components/forms/Radio.jsx":"3ca289013245","components/forms/Select.jsx":"83b251fdec1e","components/forms/Switch.jsx":"b3a6fbf26472","components/navigation/AppBar.jsx":"64203667b033","components/navigation/BottomNav.jsx":"0a041bfd54cd","components/navigation/Tabs.jsx":"d1a0bbd8f9a2","ui_kits/app/CreateEventScreen.jsx":"8d1162680328","ui_kits/app/EventDetailScreen.jsx":"79450b73eff9","ui_kits/app/HomeScreen.jsx":"61cfb2bcb3ed","ui_kits/app/PeopleScreen.jsx":"ea544ea94f46","ui_kits/app/data.js":"da0b37343c2c"},"inlinedExternals":[],"unexposedExports":[]} */

(() => {

const __ds_ns = (window.YourSpaceDesignSystem_d7e9f7 = window.YourSpaceDesignSystem_d7e9f7 || {});

const __ds_scope = {};

(__ds_ns.__errors = __ds_ns.__errors || []);

// components/core/Avatar.jsx
try { (() => {
const palettes = [['#F8E5E8', '#B11E2E'], ['#E4EAFB', '#1D4ED8'], ['#E8F2EC', '#15803D'], ['#FAF3E0', '#CA8A04'], ['#F5F5F5', '#6B6B6B']];
function Avatar({
  name = '',
  size = 44,
  src,
  tone,
  style
}) {
  const initials = name.trim().split(/\s+/).slice(0, 2).map(w => w[0]).join('').toUpperCase();
  const idx = tone != null ? tone : name.length ? name.charCodeAt(0) % palettes.length : 0;
  const [bg, fg] = palettes[idx % palettes.length];
  if (src) return React.createElement('img', {
    src,
    alt: name,
    style: {
      width: size,
      height: size,
      borderRadius: '50%',
      objectFit: 'cover',
      ...style
    }
  });
  return React.createElement('div', {
    style: {
      width: size,
      height: size,
      borderRadius: '50%',
      background: bg,
      color: fg,
      display: 'inline-flex',
      alignItems: 'center',
      justifyContent: 'center',
      font: `700 ${Math.round(size * 0.36)}px/1 var(--font-body)`,
      flexShrink: 0,
      ...style
    }
  }, initials);
}
function AvatarStack({
  names = [],
  size = 32,
  max = 4,
  style
}) {
  const shown = names.slice(0, max),
    extra = names.length - shown.length;
  return React.createElement('div', {
    style: {
      display: 'flex',
      ...style
    }
  }, shown.map((n, i) => React.createElement(Avatar, {
    key: i,
    name: n,
    size,
    style: {
      marginLeft: i ? -size * 0.3 : 0,
      boxShadow: '0 0 0 2px #fff'
    }
  })), extra > 0 ? React.createElement('div', {
    style: {
      width: size,
      height: size,
      borderRadius: '50%',
      background: 'var(--input-fill)',
      color: 'var(--text-secondary)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      font: `600 ${Math.round(size * 0.34)}px/1 var(--font-micro)`,
      marginLeft: -size * 0.3,
      boxShadow: '0 0 0 2px #fff'
    }
  }, '+' + extra) : null);
}
Object.assign(__ds_scope, { Avatar, AvatarStack });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Avatar.jsx", error: String((e && e.message) || e) }); }

// components/core/Badge.jsx
try { (() => {
const tones = {
  success: ['var(--tint-success)', 'var(--color-success)'],
  warning: ['var(--tint-warning)', 'var(--color-warning)'],
  error: ['var(--tint-error)', 'var(--color-error)'],
  info: ['var(--tint-info)', 'var(--color-info)'],
  brand: ['var(--brand-red-soft)', 'var(--brand-primary)'],
  neutral: ['var(--input-fill)', 'var(--text-secondary)']
};
function Badge({
  tone = 'neutral',
  icon,
  children,
  style
}) {
  const [bg, fg] = tones[tone] || tones.neutral;
  return React.createElement('span', {
    style: {
      display: 'inline-flex',
      alignItems: 'center',
      gap: 4,
      padding: '4px 12px',
      borderRadius: 999,
      background: bg,
      color: fg,
      font: 'var(--text-label-lg)',
      fontFamily: 'var(--font-body)',
      ...style
    }
  }, icon ? React.createElement('span', {
    className: 'msr',
    style: {
      fontSize: 15
    }
  }, icon) : null, children);
}
Object.assign(__ds_scope, { Badge });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Badge.jsx", error: String((e && e.message) || e) }); }

// components/core/Button.jsx
try { (() => {
function Button({
  variant = 'primary',
  size = 'md',
  disabled = false,
  icon,
  fullWidth = false,
  children,
  onClick,
  style
}) {
  const h = size === 'sm' ? 40 : 52;
  const base = {
    display: fullWidth ? 'flex' : 'inline-flex',
    width: fullWidth ? '100%' : undefined,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    height: h,
    padding: size === 'sm' ? '0 20px' : '0 28px',
    borderRadius: 'var(--radius-button)',
    font: size === 'sm' ? 'var(--text-label-lg)' : 'var(--text-title-md)',
    cursor: disabled ? 'default' : 'pointer',
    border: 'none',
    background: 'transparent',
    opacity: disabled ? 0.4 : 1,
    transition: 'background .15s,transform .1s',
    boxSizing: 'border-box',
    fontFamily: 'var(--font-body)'
  };
  const variants = {
    primary: {
      background: 'var(--brand-primary)',
      color: '#fff',
      boxShadow: disabled ? 'none' : 'var(--shadow-brand)'
    },
    secondary: {
      background: 'transparent',
      color: 'var(--brand-primary)',
      border: '1px solid var(--brand-primary)'
    },
    text: {
      background: 'transparent',
      color: 'var(--brand-primary)'
    },
    dark: {
      background: 'var(--brand-black)',
      color: '#fff'
    },
    soft: {
      background: 'var(--brand-red-soft)',
      color: 'var(--brand-primary)'
    }
  };
  const [pressed, setPressed] = React.useState(false);
  return React.createElement('button', {
    onClick: disabled ? undefined : onClick,
    disabled,
    onMouseDown: () => setPressed(true),
    onMouseUp: () => setPressed(false),
    onMouseLeave: () => setPressed(false),
    onMouseEnter: e => {
      if (!disabled && variant === 'primary') e.currentTarget.style.background = 'var(--brand-primary-dark)';
    },
    onMouseOut: e => {
      if (variant === 'primary') e.currentTarget.style.background = 'var(--brand-primary)';
    },
    style: {
      ...base,
      ...variants[variant],
      transform: pressed && !disabled ? 'scale(0.98)' : 'none',
      ...style
    }
  }, icon ? React.createElement('span', {
    className: 'msr',
    style: {
      fontSize: size === 'sm' ? 18 : 20
    }
  }, icon) : null, children);
}
Object.assign(__ds_scope, { Button });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Button.jsx", error: String((e && e.message) || e) }); }

// components/core/Chip.jsx
try { (() => {
function Chip({
  selected = false,
  icon,
  count,
  children,
  onClick,
  style
}) {
  return React.createElement('button', {
    onClick,
    style: {
      display: 'inline-flex',
      alignItems: 'center',
      gap: 6,
      height: 36,
      padding: '0 16px',
      borderRadius: 'var(--radius-chip)',
      border: selected ? '1px solid var(--brand-primary)' : '1px solid var(--divider)',
      background: selected ? 'var(--brand-red-soft)' : 'var(--surface)',
      color: selected ? 'var(--brand-primary)' : 'var(--text-primary)',
      font: 'var(--text-label-lg)',
      fontFamily: 'var(--font-body)',
      cursor: 'pointer',
      transition: 'background .15s',
      ...style
    }
  }, icon ? React.createElement('span', {
    className: 'msr',
    style: {
      fontSize: 18
    }
  }, icon) : null, children, count != null ? React.createElement('span', {
    style: {
      font: '600 11px/1 var(--font-micro)',
      background: selected ? 'var(--brand-primary)' : 'var(--input-fill)',
      color: selected ? '#fff' : 'var(--text-secondary)',
      padding: '3px 7px',
      borderRadius: 999
    }
  }, count) : null);
}
Object.assign(__ds_scope, { Chip });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Chip.jsx", error: String((e && e.message) || e) }); }

// components/core/IconButton.jsx
try { (() => {
function IconButton({
  icon,
  variant = 'ghost',
  size = 44,
  filled = false,
  badge,
  onClick,
  style
}) {
  const variants = {
    ghost: {
      background: 'transparent',
      color: 'var(--text-primary)'
    },
    tonal: {
      background: 'var(--input-fill)',
      color: 'var(--text-primary)'
    },
    soft: {
      background: 'var(--brand-red-soft)',
      color: 'var(--brand-primary)'
    },
    primary: {
      background: 'var(--brand-primary)',
      color: '#fff',
      boxShadow: 'var(--shadow-brand)'
    }
  };
  return React.createElement('button', {
    onClick,
    style: {
      position: 'relative',
      width: size,
      height: size,
      borderRadius: '50%',
      border: 'none',
      display: 'inline-flex',
      alignItems: 'center',
      justifyContent: 'center',
      cursor: 'pointer',
      ...variants[variant],
      ...style
    }
  }, React.createElement('span', {
    className: 'msr',
    style: {
      fontSize: Math.round(size * 0.5),
      fontVariationSettings: filled ? "'FILL' 1" : "'FILL' 0"
    }
  }, icon), badge ? React.createElement('span', {
    style: {
      position: 'absolute',
      top: 2,
      right: 2,
      minWidth: 16,
      height: 16,
      borderRadius: 8,
      background: 'var(--brand-primary)',
      color: '#fff',
      font: '600 10px/16px var(--font-micro)',
      padding: '0 4px',
      boxSizing: 'border-box'
    }
  }, badge) : null);
}
Object.assign(__ds_scope, { IconButton });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/IconButton.jsx", error: String((e && e.message) || e) }); }

// components/display/Card.jsx
try { (() => {
function Card({
  elevated = true,
  padding = 20,
  onClick,
  children,
  style
}) {
  return React.createElement('div', {
    onClick,
    style: {
      background: 'var(--surface-card)',
      borderRadius: 'var(--radius-card)',
      boxShadow: elevated ? 'var(--shadow-soft)' : 'none',
      padding,
      cursor: onClick ? 'pointer' : 'default',
      boxSizing: 'border-box',
      ...style
    }
  }, children);
}
Object.assign(__ds_scope, { Card });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/display/Card.jsx", error: String((e && e.message) || e) }); }

// components/display/EmptyState.jsx
try { (() => {
function EmptyState({
  icon = 'celebration',
  title,
  body,
  action,
  style
}) {
  return React.createElement('div', {
    style: {
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      textAlign: 'center',
      gap: 8,
      padding: '40px 32px',
      ...style
    }
  }, React.createElement('div', {
    style: {
      width: 72,
      height: 72,
      borderRadius: '50%',
      background: 'var(--brand-red-soft)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      marginBottom: 8
    }
  }, React.createElement('span', {
    className: 'msr',
    style: {
      fontSize: 34,
      color: 'var(--brand-primary)'
    }
  }, icon)), React.createElement('div', {
    style: {
      font: 'var(--text-headline-sm)'
    }
  }, title), body ? React.createElement('div', {
    style: {
      font: 'var(--text-body-md)',
      color: 'var(--text-secondary)',
      maxWidth: 280
    }
  }, body) : null, action ? React.createElement('div', {
    style: {
      marginTop: 12
    }
  }, action) : null);
}
Object.assign(__ds_scope, { EmptyState });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/display/EmptyState.jsx", error: String((e && e.message) || e) }); }

// components/display/ListTile.jsx
try { (() => {
function ListTile({
  title,
  subtitle,
  avatarName,
  avatarSrc,
  icon,
  trailing,
  divider = false,
  onClick,
  style
}) {
  return React.createElement(React.Fragment, null, React.createElement('div', {
    onClick,
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 12,
      padding: '12px 16px',
      minHeight: 56,
      cursor: onClick ? 'pointer' : 'default',
      background: 'transparent',
      ...style
    }
  }, avatarName || avatarSrc ? React.createElement(__ds_scope.Avatar, {
    name: avatarName,
    src: avatarSrc,
    size: 44
  }) : icon ? React.createElement('span', {
    style: {
      width: 44,
      height: 44,
      borderRadius: '50%',
      background: 'var(--input-fill)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      flexShrink: 0
    }
  }, React.createElement('span', {
    className: 'msr',
    style: {
      fontSize: 20,
      color: 'var(--text-secondary)'
    }
  }, icon)) : null, React.createElement('div', {
    style: {
      flex: 1,
      minWidth: 0
    }
  }, React.createElement('div', {
    style: {
      font: 'var(--text-label-lg)',
      fontWeight: 700,
      color: 'var(--text-primary)',
      whiteSpace: 'nowrap',
      overflow: 'hidden',
      textOverflow: 'ellipsis'
    }
  }, title), subtitle ? React.createElement('div', {
    style: {
      font: 'var(--text-body-sm)',
      color: 'var(--text-secondary)',
      whiteSpace: 'nowrap',
      overflow: 'hidden',
      textOverflow: 'ellipsis'
    }
  }, subtitle) : null), trailing || null), divider ? React.createElement('div', {
    style: {
      height: 1,
      background: 'var(--divider)',
      marginLeft: 72
    }
  }) : null);
}
Object.assign(__ds_scope, { ListTile });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/display/ListTile.jsx", error: String((e && e.message) || e) }); }

// components/feedback/Dialog.jsx
try { (() => {
function Dialog({
  open = true,
  title,
  body,
  confirmLabel = 'Confirm',
  cancelLabel = 'Cancel',
  destructive = false,
  onConfirm,
  onCancel,
  inline = false,
  style
}) {
  if (!open) return null;
  const card = React.createElement('div', {
    style: {
      background: '#fff',
      borderRadius: 'var(--radius-card)',
      boxShadow: 'var(--shadow-soft-lg)',
      padding: 24,
      width: 320,
      maxWidth: '90%',
      display: 'flex',
      flexDirection: 'column',
      gap: 8,
      boxSizing: 'border-box',
      ...style
    }
  }, React.createElement('div', {
    style: {
      font: 'var(--text-headline-sm)'
    }
  }, title), body ? React.createElement('div', {
    style: {
      font: 'var(--text-body-md)',
      color: 'var(--text-secondary)'
    }
  }, body) : null, React.createElement('div', {
    style: {
      display: 'flex',
      gap: 10,
      marginTop: 12
    }
  }, React.createElement(__ds_scope.Button, {
    variant: 'text',
    size: 'sm',
    onClick: onCancel,
    style: {
      flex: 1
    }
  }, cancelLabel), React.createElement(__ds_scope.Button, {
    size: 'sm',
    onClick: onConfirm,
    style: {
      flex: 1,
      background: destructive ? 'var(--color-error)' : undefined,
      boxShadow: destructive ? 'none' : undefined
    }
  }, confirmLabel)));
  if (inline) return card;
  return React.createElement('div', {
    style: {
      position: 'fixed',
      inset: 0,
      background: 'rgba(11,11,11,0.4)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      zIndex: 100
    }
  }, card);
}
Object.assign(__ds_scope, { Dialog });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/feedback/Dialog.jsx", error: String((e && e.message) || e) }); }

// components/feedback/Snackbar.jsx
try { (() => {
function Snackbar({
  message,
  actionLabel,
  onAction,
  tone = 'dark',
  style
}) {
  const bg = tone === 'dark' ? 'var(--brand-black)' : tone === 'success' ? 'var(--color-success)' : tone === 'error' ? 'var(--color-error)' : 'var(--brand-black)';
  return React.createElement('div', {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 12,
      background: bg,
      color: '#fff',
      borderRadius: 'var(--radius-snackbar)',
      padding: '14px 16px',
      boxShadow: 'var(--shadow-soft-lg)',
      ...style
    }
  }, React.createElement('span', {
    style: {
      flex: 1,
      font: 'var(--text-body-md)'
    }
  }, message), actionLabel ? React.createElement('button', {
    onClick: onAction,
    style: {
      border: 'none',
      background: 'transparent',
      color: tone === 'dark' ? '#F8A5AE' : '#fff',
      font: 'var(--text-label-lg)',
      fontWeight: 700,
      fontFamily: 'var(--font-body)',
      cursor: 'pointer',
      padding: 0
    }
  }, actionLabel) : null);
}
Object.assign(__ds_scope, { Snackbar });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/feedback/Snackbar.jsx", error: String((e && e.message) || e) }); }

// components/forms/Checkbox.jsx
try { (() => {
function Checkbox({
  checked = false,
  label,
  onChange,
  style
}) {
  return React.createElement('label', {
    onClick: () => onChange && onChange(!checked),
    style: {
      display: 'inline-flex',
      alignItems: 'center',
      gap: 10,
      cursor: 'pointer',
      minHeight: 44,
      ...style
    }
  }, React.createElement('span', {
    style: {
      width: 24,
      height: 24,
      borderRadius: 8,
      border: checked ? 'none' : '2px solid var(--text-hint)',
      background: checked ? 'var(--brand-primary)' : 'transparent',
      display: 'inline-flex',
      alignItems: 'center',
      justifyContent: 'center',
      transition: 'background .15s',
      flexShrink: 0
    }
  }, checked ? React.createElement('span', {
    className: 'msr',
    style: {
      fontSize: 17,
      color: '#fff'
    }
  }, 'check') : null), label ? React.createElement('span', {
    style: {
      font: 'var(--text-body-md)'
    }
  }, label) : null);
}
Object.assign(__ds_scope, { Checkbox });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/Checkbox.jsx", error: String((e && e.message) || e) }); }

// components/forms/Input.jsx
try { (() => {
function Input({
  label,
  placeholder,
  value,
  onChange,
  icon,
  error,
  hint,
  type = 'text',
  multiline = false,
  dir,
  style
}) {
  const [focus, setFocus] = React.useState(false);
  const border = error ? '1.5px solid var(--color-error)' : focus ? '1.5px solid var(--brand-primary)' : '1.5px solid transparent';
  const Tag = multiline ? 'textarea' : 'input';
  return React.createElement('label', {
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 6,
      ...style
    }
  }, label ? React.createElement('span', {
    style: {
      font: 'var(--text-label-lg)',
      color: 'var(--text-primary)'
    }
  }, label) : null, React.createElement('span', {
    style: {
      display: 'flex',
      alignItems: multiline ? 'flex-start' : 'center',
      gap: 10,
      background: 'var(--input-fill)',
      borderRadius: 'var(--radius-input)',
      border,
      padding: multiline ? '14px 16px' : '0 16px',
      minHeight: multiline ? undefined : 52,
      boxSizing: 'border-box',
      transition: 'border-color .15s'
    }
  }, icon ? React.createElement('span', {
    className: 'msr',
    style: {
      fontSize: 20,
      color: focus ? 'var(--brand-primary)' : 'var(--text-hint)',
      marginTop: multiline ? 2 : 0
    }
  }, icon) : null, React.createElement(Tag, {
    type: multiline ? undefined : type,
    placeholder,
    value,
    dir,
    rows: multiline ? 3 : undefined,
    onChange: e => onChange && onChange(e.target.value),
    onFocus: () => setFocus(true),
    onBlur: () => setFocus(false),
    style: {
      flex: 1,
      border: 'none',
      outline: 'none',
      background: 'transparent',
      font: 'var(--text-body-md)',
      fontFamily: 'var(--font-body)',
      color: 'var(--text-primary)',
      padding: 0,
      resize: 'none'
    }
  })), error ? React.createElement('span', {
    style: {
      font: 'var(--text-body-sm)',
      color: 'var(--color-error)'
    }
  }, error) : hint ? React.createElement('span', {
    style: {
      font: 'var(--text-body-sm)',
      color: 'var(--text-hint)'
    }
  }, hint) : null);
}
Object.assign(__ds_scope, { Input });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/Input.jsx", error: String((e && e.message) || e) }); }

// components/forms/Radio.jsx
try { (() => {
function Radio({
  checked = false,
  label,
  onChange,
  style
}) {
  return React.createElement('label', {
    onClick: () => onChange && onChange(true),
    style: {
      display: 'inline-flex',
      alignItems: 'center',
      gap: 10,
      cursor: 'pointer',
      minHeight: 44,
      ...style
    }
  }, React.createElement('span', {
    style: {
      width: 24,
      height: 24,
      borderRadius: '50%',
      border: checked ? '7px solid var(--brand-primary)' : '2px solid var(--text-hint)',
      boxSizing: 'border-box',
      transition: 'border .15s',
      flexShrink: 0,
      background: '#fff'
    }
  }), label ? React.createElement('span', {
    style: {
      font: 'var(--text-body-md)'
    }
  }, label) : null);
}
Object.assign(__ds_scope, { Radio });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/Radio.jsx", error: String((e && e.message) || e) }); }

// components/forms/Select.jsx
try { (() => {
function Select({
  label,
  placeholder = 'Choose…',
  value,
  options = [],
  onChange,
  style
}) {
  const [open, setOpen] = React.useState(false);
  return React.createElement('div', {
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 6,
      position: 'relative',
      ...style
    }
  }, label ? React.createElement('span', {
    style: {
      font: 'var(--text-label-lg)'
    }
  }, label) : null, React.createElement('button', {
    onClick: () => setOpen(o => !o),
    style: {
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
      gap: 10,
      height: 52,
      padding: '0 16px',
      background: 'var(--input-fill)',
      border: open ? '1.5px solid var(--brand-primary)' : '1.5px solid transparent',
      borderRadius: 'var(--radius-input)',
      font: 'var(--text-body-md)',
      fontFamily: 'var(--font-body)',
      color: value ? 'var(--text-primary)' : 'var(--text-hint)',
      cursor: 'pointer',
      boxSizing: 'border-box'
    }
  }, value || placeholder, React.createElement('span', {
    className: 'msr',
    style: {
      fontSize: 20,
      color: 'var(--text-hint)',
      transform: open ? 'rotate(180deg)' : 'none',
      transition: 'transform .15s'
    }
  }, 'expand_more')), open ? React.createElement('div', {
    style: {
      position: 'absolute',
      top: '100%',
      left: 0,
      right: 0,
      marginTop: 6,
      background: '#fff',
      borderRadius: 14,
      boxShadow: 'var(--shadow-soft-lg)',
      padding: 6,
      zIndex: 20,
      display: 'flex',
      flexDirection: 'column',
      gap: 2
    }
  }, options.map(o => React.createElement('button', {
    key: o,
    onClick: () => {
      onChange && onChange(o);
      setOpen(false);
    },
    style: {
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
      padding: '12px 14px',
      border: 'none',
      borderRadius: 10,
      background: o === value ? 'var(--brand-red-soft)' : 'transparent',
      color: o === value ? 'var(--brand-primary)' : 'var(--text-primary)',
      font: 'var(--text-body-md)',
      fontFamily: 'var(--font-body)',
      cursor: 'pointer',
      textAlign: 'left'
    }
  }, o, o === value ? React.createElement('span', {
    className: 'msr',
    style: {
      fontSize: 18
    }
  }, 'check') : null))) : null);
}
Object.assign(__ds_scope, { Select });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/Select.jsx", error: String((e && e.message) || e) }); }

// components/forms/Switch.jsx
try { (() => {
function Switch({
  checked = false,
  label,
  onChange,
  style
}) {
  return React.createElement('label', {
    onClick: () => onChange && onChange(!checked),
    style: {
      display: 'inline-flex',
      alignItems: 'center',
      gap: 12,
      cursor: 'pointer',
      minHeight: 44,
      ...style
    }
  }, React.createElement('span', {
    style: {
      width: 48,
      height: 28,
      borderRadius: 14,
      background: checked ? 'var(--brand-primary)' : 'var(--divider)',
      position: 'relative',
      transition: 'background .15s',
      flexShrink: 0
    }
  }, React.createElement('span', {
    style: {
      position: 'absolute',
      top: 3,
      left: checked ? 23 : 3,
      width: 22,
      height: 22,
      borderRadius: '50%',
      background: '#fff',
      boxShadow: '0 1px 3px rgba(0,0,0,0.2)',
      transition: 'left .15s'
    }
  })), label ? React.createElement('span', {
    style: {
      font: 'var(--text-body-md)'
    }
  }, label) : null);
}
Object.assign(__ds_scope, { Switch });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/Switch.jsx", error: String((e && e.message) || e) }); }

// components/navigation/AppBar.jsx
try { (() => {
function AppBar({
  title,
  onBack,
  trailing,
  dark = false,
  style
}) {
  return React.createElement('div', {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 8,
      height: 56,
      padding: '0 8px',
      background: dark ? 'var(--brand-black)' : 'var(--surface)',
      color: dark ? '#fff' : 'var(--text-primary)',
      boxSizing: 'border-box',
      ...style
    }
  }, onBack ? React.createElement(__ds_scope.IconButton, {
    icon: 'arrow_back',
    onClick: onBack,
    style: {
      color: 'inherit'
    }
  }) : React.createElement('span', {
    style: {
      width: 44
    }
  }), React.createElement('div', {
    style: {
      flex: 1,
      textAlign: 'center',
      font: 'var(--text-title-lg)',
      color: 'inherit',
      whiteSpace: 'nowrap',
      overflow: 'hidden',
      textOverflow: 'ellipsis'
    }
  }, title), trailing || React.createElement('span', {
    style: {
      width: 44
    }
  }));
}
Object.assign(__ds_scope, { AppBar });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/navigation/AppBar.jsx", error: String((e && e.message) || e) }); }

// components/navigation/BottomNav.jsx
try { (() => {
function BottomNav({
  items = [],
  active = 0,
  onSelect,
  style
}) {
  return React.createElement('div', {
    style: {
      display: 'flex',
      background: 'var(--surface)',
      boxShadow: '0 -4px 24px rgba(0,0,0,0.06)',
      padding: '8px 8px calc(8px + env(safe-area-inset-bottom,0px))',
      ...style
    }
  }, items.map((it, i) => {
    const on = i === active;
    return React.createElement('button', {
      key: i,
      onClick: () => onSelect && onSelect(i),
      style: {
        flex: 1,
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        gap: 2,
        padding: '6px 0',
        border: 'none',
        background: 'transparent',
        cursor: 'pointer',
        minHeight: 44
      }
    }, React.createElement('span', {
      style: {
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        width: 56,
        height: 30,
        borderRadius: 15,
        background: on ? 'var(--brand-red-soft)' : 'transparent',
        transition: 'background .15s'
      }
    }, React.createElement('span', {
      className: 'msr',
      style: {
        fontSize: 22,
        color: on ? 'var(--brand-primary)' : 'var(--text-secondary)',
        fontVariationSettings: on ? "'FILL' 1" : "'FILL' 0"
      }
    }, it.icon)), React.createElement('span', {
      style: {
        font: '600 11px/1.3 var(--font-body)',
        color: on ? 'var(--brand-primary)' : 'var(--text-secondary)'
      }
    }, it.label));
  }));
}
Object.assign(__ds_scope, { BottomNav });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/navigation/BottomNav.jsx", error: String((e && e.message) || e) }); }

// components/navigation/Tabs.jsx
try { (() => {
function Tabs({
  tabs = [],
  active = 0,
  onSelect,
  style
}) {
  return React.createElement('div', {
    style: {
      display: 'flex',
      gap: 8,
      padding: 4,
      background: 'var(--input-fill)',
      borderRadius: 999,
      ...style
    }
  }, tabs.map((t, i) => {
    const on = i === active;
    return React.createElement('button', {
      key: i,
      onClick: () => onSelect && onSelect(i),
      style: {
        flex: 1,
        height: 40,
        border: 'none',
        borderRadius: 999,
        background: on ? 'var(--surface)' : 'transparent',
        color: on ? 'var(--brand-primary)' : 'var(--text-secondary)',
        font: 'var(--text-label-lg)',
        fontWeight: 700,
        fontFamily: 'var(--font-body)',
        cursor: 'pointer',
        boxShadow: on ? 'var(--shadow-soft)' : 'none',
        transition: 'background .15s'
      }
    }, t);
  }));
}
Object.assign(__ds_scope, { Tabs });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/navigation/Tabs.jsx", error: String((e && e.message) || e) }); }

// ui_kits/app/CreateEventScreen.jsx
try { (() => {
function CreateEventScreen({
  onBack,
  onDone
}) {
  const {
    AppBar,
    Input,
    Select,
    Card,
    Checkbox,
    Switch,
    Button
  } = window.YourSpaceDesignSystem_d7e9f7;
  const D = window.YS_DATA;
  const [name, setName] = React.useState('');
  const [occ, setOcc] = React.useState('Dinner');
  const [sel, setSel] = React.useState({
    'Sara Adel': true,
    'Nour Hassan': true
  });
  const [remind, setRemind] = React.useState(true);
  const n = Object.values(sel).filter(Boolean).length;
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      minHeight: '100%'
    }
  }, /*#__PURE__*/React.createElement(AppBar, {
    title: "New event",
    onBack: onBack
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 16,
      padding: 16,
      flex: 1
    }
  }, /*#__PURE__*/React.createElement(Input, {
    label: "Event name",
    placeholder: "e.g. Dinner at ours",
    icon: "celebration",
    value: name,
    onChange: setName
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'grid',
      gridTemplateColumns: '1fr 1fr',
      gap: 12
    }
  }, /*#__PURE__*/React.createElement(Select, {
    label: "Occasion",
    options: ["Dinner", "Engagement", "Wedding", "Birthday", "Iftar"],
    value: occ,
    onChange: setOcc
  }), /*#__PURE__*/React.createElement(Input, {
    label: "Date & time",
    placeholder: "Fri, Aug 7 \xB7 8 pm",
    icon: "schedule"
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      font: 'var(--text-label-lg)',
      fontWeight: 700
    }
  }, "Guest list"), /*#__PURE__*/React.createElement(Card, {
    padding: 12,
    style: {
      display: 'flex',
      flexDirection: 'column'
    }
  }, D.people.slice(0, 4).map(p => /*#__PURE__*/React.createElement(Checkbox, {
    key: p.name,
    checked: !!sel[p.name],
    label: `${p.name} — ${p.group}`,
    onChange: v => setSel(s => ({
      ...s,
      [p.name]: v
    }))
  }))), /*#__PURE__*/React.createElement(Switch, {
    checked: remind,
    onChange: setRemind,
    label: "Remind me if invites go unanswered"
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      padding: '12px 16px 20px',
      background: 'var(--surface)',
      boxShadow: '0 -4px 24px rgba(0,0,0,0.06)'
    }
  }, /*#__PURE__*/React.createElement(Button, {
    fullWidth: true,
    icon: "send",
    onClick: onDone
  }, n ? `Send invites to ${n} guests` : 'Send invites')));
}
Object.assign(window, {
  CreateEventScreen
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/app/CreateEventScreen.jsx", error: String((e && e.message) || e) }); }

// ui_kits/app/EventDetailScreen.jsx
try { (() => {
function EventDetailScreen({
  event,
  onBack
}) {
  const {
    AppBar,
    Card,
    Tabs,
    ListTile,
    Badge,
    Button,
    IconButton,
    Snackbar
  } = window.YourSpaceDesignSystem_d7e9f7;
  const D = window.YS_DATA;
  const [tab, setTab] = React.useState(0);
  const [sent, setSent] = React.useState(false);
  const toneOf = {
    Confirmed: 'success',
    Pending: 'warning',
    Declined: 'error',
    Maybe: 'info'
  };
  const buckets = [['Confirmed', 'Maybe'], ['Pending'], ['Declined']];
  const list = D.people.filter(p => buckets[tab].includes(p.status));
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      minHeight: '100%'
    }
  }, /*#__PURE__*/React.createElement(AppBar, {
    title: "Event details",
    onBack: onBack,
    trailing: /*#__PURE__*/React.createElement(IconButton, {
      icon: "share"
    })
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 16,
      padding: 16,
      flex: 1
    }
  }, /*#__PURE__*/React.createElement(Card, {
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 6
    }
  }, /*#__PURE__*/React.createElement(Badge, {
    tone: "brand",
    style: {
      alignSelf: 'flex-start'
    }
  }, event.occasion), /*#__PURE__*/React.createElement("div", {
    style: {
      font: 'var(--text-headline-sm)',
      fontFamily: 'var(--font-display)'
    }
  }, event.title), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 6,
      font: 'var(--text-body-sm)',
      color: 'var(--text-secondary)'
    }
  }, /*#__PURE__*/React.createElement("span", {
    className: "msr",
    style: {
      fontSize: 16
    }
  }, "schedule"), event.date), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 6,
      font: 'var(--text-body-sm)',
      color: 'var(--text-secondary)'
    }
  }, /*#__PURE__*/React.createElement("span", {
    className: "msr",
    style: {
      fontSize: 16
    }
  }, "group"), event.guests, " guests \xB7 ", event.confirmed, " confirmed \xB7 ", event.pending, " pending")), /*#__PURE__*/React.createElement(Tabs, {
    tabs: ["Going", "Pending", "Declined"],
    active: tab,
    onSelect: setTab
  }), /*#__PURE__*/React.createElement(Card, {
    padding: 8
  }, list.length ? list.map((p, i) => /*#__PURE__*/React.createElement(ListTile, {
    key: p.name,
    avatarName: p.name,
    title: p.name,
    subtitle: `${p.group} · invited ${p.invited}×`,
    trailing: /*#__PURE__*/React.createElement(Badge, {
      tone: toneOf[p.status]
    }, p.status),
    divider: i < list.length - 1
  })) : /*#__PURE__*/React.createElement("div", {
    style: {
      padding: '24px 16px',
      textAlign: 'center',
      font: 'var(--text-body-md)',
      color: 'var(--text-hint)'
    }
  }, "No one here yet")), sent ? /*#__PURE__*/React.createElement(Snackbar, {
    message: "Reminders sent to pending guests",
    actionLabel: "Undo",
    onAction: () => setSent(false)
  }) : null), /*#__PURE__*/React.createElement("div", {
    style: {
      padding: '12px 16px 20px',
      background: 'var(--surface)',
      boxShadow: '0 -4px 24px rgba(0,0,0,0.06)'
    }
  }, /*#__PURE__*/React.createElement(Button, {
    fullWidth: true,
    icon: "send",
    onClick: () => setSent(true)
  }, "Send reminders")));
}
Object.assign(window, {
  EventDetailScreen
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/app/EventDetailScreen.jsx", error: String((e && e.message) || e) }); }

// ui_kits/app/HomeScreen.jsx
try { (() => {
function HomeScreen({
  onOpenEvent,
  onCreate
}) {
  const {
    Card,
    Button,
    IconButton,
    Badge,
    Avatar,
    AvatarStack
  } = window.YourSpaceDesignSystem_d7e9f7;
  const D = window.YS_DATA;
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 16,
      padding: '16px 16px 24px'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 12
    }
  }, /*#__PURE__*/React.createElement(Avatar, {
    name: "Joe Nasser",
    size: 44
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      font: 'var(--text-body-sm)',
      color: 'var(--text-secondary)'
    }
  }, "Good evening"), /*#__PURE__*/React.createElement("div", {
    style: {
      font: 'var(--text-headline-sm)',
      fontFamily: 'var(--font-display)'
    }
  }, "Hi ", D.me)), /*#__PURE__*/React.createElement(IconButton, {
    icon: "notifications",
    badge: 2,
    variant: "tonal"
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      font: 'var(--text-label-sm)',
      letterSpacing: 'var(--ls-label-sm)',
      color: 'var(--text-hint)',
      textTransform: 'uppercase',
      fontFamily: 'var(--font-micro)'
    }
  }, "Upcoming"), D.events.map(e => /*#__PURE__*/React.createElement(Card, {
    key: e.id,
    onClick: () => onOpenEvent(e),
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 10
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      justifyContent: 'space-between',
      alignItems: 'flex-start',
      gap: 8
    }
  }, /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    style: {
      font: 'var(--text-title-md)'
    }
  }, e.title), /*#__PURE__*/React.createElement("div", {
    style: {
      font: 'var(--text-body-sm)',
      color: 'var(--text-secondary)'
    }
  }, e.date)), /*#__PURE__*/React.createElement(Badge, {
    tone: "brand"
  }, e.occasion)), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between'
    }
  }, /*#__PURE__*/React.createElement(AvatarStack, {
    names: window.YS_DATA.people.map(p => p.name),
    size: 30,
    max: 4
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      font: 'var(--text-body-sm)',
      color: 'var(--text-secondary)'
    }
  }, e.guests, " guests \xB7 ", e.confirmed, " confirmed")))), /*#__PURE__*/React.createElement("div", {
    style: {
      font: 'var(--text-label-sm)',
      letterSpacing: 'var(--ls-label-sm)',
      color: 'var(--text-hint)',
      textTransform: 'uppercase',
      fontFamily: 'var(--font-micro)',
      marginTop: 4
    }
  }, "Time to return the favor"), D.owed.map((o, i) => /*#__PURE__*/React.createElement(Card, {
    key: i,
    padding: 16,
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 12
    }
  }, /*#__PURE__*/React.createElement(Avatar, {
    name: o.name,
    size: 44
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      font: 'var(--text-label-lg)',
      fontWeight: 700
    }
  }, o.name), /*#__PURE__*/React.createElement("div", {
    style: {
      font: 'var(--text-body-sm)',
      color: 'var(--text-secondary)'
    }
  }, o.what, " \u2014 ", o.when)), /*#__PURE__*/React.createElement(Button, {
    size: "sm",
    variant: "soft",
    onClick: onCreate
  }, "Invite"))));
}
Object.assign(window, {
  HomeScreen
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/app/HomeScreen.jsx", error: String((e && e.message) || e) }); }

// ui_kits/app/PeopleScreen.jsx
try { (() => {
function PeopleScreen() {
  const {
    Card,
    Chip,
    ListTile,
    Badge,
    Input,
    IconButton
  } = window.YourSpaceDesignSystem_d7e9f7;
  const D = window.YS_DATA;
  const [q, setQ] = React.useState('');
  const [g, setG] = React.useState(null);
  const list = D.people.filter(p => (!g || p.group === g) && p.name.toLowerCase().includes(q.toLowerCase()));
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 14,
      padding: '16px 16px 24px'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 10
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      font: 'var(--text-headline-sm)',
      fontFamily: 'var(--font-display)'
    }
  }, "People"), /*#__PURE__*/React.createElement(IconButton, {
    icon: "person_add",
    variant: "soft"
  })), /*#__PURE__*/React.createElement(Input, {
    placeholder: "Search people\u2026",
    icon: "search",
    value: q,
    onChange: setQ
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 8,
      overflowX: 'auto',
      paddingBottom: 2
    }
  }, D.groups.map(gr => /*#__PURE__*/React.createElement(Chip, {
    key: gr.name,
    icon: gr.icon,
    count: gr.count,
    selected: g === gr.name,
    onClick: () => setG(g === gr.name ? null : gr.name)
  }, gr.name))), /*#__PURE__*/React.createElement(Card, {
    padding: 8
  }, list.map((p, i) => /*#__PURE__*/React.createElement(ListTile, {
    key: p.name,
    avatarName: p.name,
    title: p.name,
    subtitle: `${p.group} · invited ${p.invited}×`,
    trailing: p.invited === 0 ? /*#__PURE__*/React.createElement(Badge, {
      tone: "brand"
    }, "Never invited") : /*#__PURE__*/React.createElement("span", {
      className: "msr",
      style: {
        color: 'var(--text-hint)',
        fontSize: 20
      }
    }, "chevron_right"),
    divider: i < list.length - 1
  }))));
}
Object.assign(window, {
  PeopleScreen
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/app/PeopleScreen.jsx", error: String((e && e.message) || e) }); }

// ui_kits/app/data.js
try { (() => {
window.YS_DATA = {
  me: 'Joe',
  groups: [{
    name: 'Family',
    count: 24,
    icon: 'family_restroom'
  }, {
    name: 'Work friends',
    count: 11,
    icon: 'work'
  }, {
    name: 'Neighbors',
    count: 8,
    icon: 'home'
  }, {
    name: 'College',
    count: 15,
    icon: 'school'
  }],
  people: [{
    name: 'Sara Adel',
    group: 'Family',
    invited: 2,
    status: 'Confirmed'
  }, {
    name: 'Omar Fahmy',
    group: 'Work friends',
    invited: 1,
    status: 'Pending'
  }, {
    name: 'Nour Hassan',
    group: 'Family',
    invited: 3,
    status: 'Confirmed'
  }, {
    name: 'Hana Ali',
    group: 'Neighbors',
    invited: 0,
    status: 'Pending'
  }, {
    name: 'Zein Omar',
    group: 'College',
    invited: 1,
    status: 'Declined'
  }, {
    name: 'Laila Kamel',
    group: 'Family',
    invited: 2,
    status: 'Maybe'
  }],
  events: [{
    id: 1,
    title: "Dinner at ours",
    date: 'Fri, Aug 7 · 8:00 pm',
    occasion: 'Dinner',
    guests: 12,
    confirmed: 8,
    pending: 3,
    declined: 1
  }, {
    id: 2,
    title: "Mum's birthday",
    date: 'Sat, Aug 22 · 6:30 pm',
    occasion: 'Birthday',
    guests: 24,
    confirmed: 15,
    pending: 9,
    declined: 0
  }],
  owed: [{
    name: 'Nour Hassan',
    what: 'Invited you to iftar twice',
    when: 'last one 3 weeks ago'
  }, {
    name: 'Omar Fahmy',
    what: 'Had you over for dinner',
    when: '2 months ago'
  }]
};
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/app/data.js", error: String((e && e.message) || e) }); }

__ds_ns.Avatar = __ds_scope.Avatar;

__ds_ns.AvatarStack = __ds_scope.AvatarStack;

__ds_ns.Badge = __ds_scope.Badge;

__ds_ns.Button = __ds_scope.Button;

__ds_ns.Chip = __ds_scope.Chip;

__ds_ns.IconButton = __ds_scope.IconButton;

__ds_ns.Card = __ds_scope.Card;

__ds_ns.EmptyState = __ds_scope.EmptyState;

__ds_ns.ListTile = __ds_scope.ListTile;

__ds_ns.Dialog = __ds_scope.Dialog;

__ds_ns.Snackbar = __ds_scope.Snackbar;

__ds_ns.Checkbox = __ds_scope.Checkbox;

__ds_ns.Input = __ds_scope.Input;

__ds_ns.Radio = __ds_scope.Radio;

__ds_ns.Select = __ds_scope.Select;

__ds_ns.Switch = __ds_scope.Switch;

__ds_ns.AppBar = __ds_scope.AppBar;

__ds_ns.BottomNav = __ds_scope.BottomNav;

__ds_ns.Tabs = __ds_scope.Tabs;

})();
