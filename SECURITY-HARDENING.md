# Security Hardening Guide for GitHub Actions and Codespaces

This document provides comprehensive security hardening guidance for the NEWS Enhanced Persistent Intelligence Platform, covering GitHub Actions workflows, Codespaces configuration, and overall security best practices.

## 🔐 Executive Summary

Security hardening is critical for protecting intellectual property, preventing supply chain attacks, and maintaining the integrity of our intelligence platform. This guide provides actionable steps to secure our GitHub environment.

## 📋 Security Hardening Checklist

### 🔑 Secrets Management

#### ✅ GitHub Secrets Configuration
- [ ] **Use environment-specific secrets**: Configure secrets at organization, repository, and environment levels
- [ ] **Implement secret rotation**: Regularly rotate API keys, tokens, and credentials (quarterly minimum)
- [ ] **Use least privilege access**: Secrets should only be accessible to workflows that need them
- [ ] **Avoid logging secrets**: Never echo or log secret values in workflow outputs
- [ ] **Use encrypted secret storage**: Store all sensitive data as GitHub encrypted secrets

#### ✅ Secret Naming Conventions
```yaml
# ✅ Good - Clear, descriptive names
secrets:
  API_KEY_NEWS_SERVICE: ${{ secrets.API_KEY_NEWS_SERVICE }}
  DATABASE_CONNECTION_STRING: ${{ secrets.DATABASE_CONNECTION_STRING }}
  
# ❌ Bad - Generic or unclear names  
secrets:
  SECRET1: ${{ secrets.SECRET1 }}
  KEY: ${{ secrets.KEY }}
```

#### ✅ Secret Validation
- [ ] **Implement secret validation**: Verify secrets are properly formatted before use
- [ ] **Use conditional execution**: Skip jobs if required secrets are missing
- [ ] **Monitor secret usage**: Track which workflows access which secrets

### 🛡️ Permissions Hardening

#### ✅ Workflow Permissions
- [ ] **Use minimal permissions**: Start with no permissions and add only what's needed
- [ ] **Avoid `write-all` permissions**: Never use broad write permissions
- [ ] **Specify explicit permissions**: Define exact permissions for each job

```yaml
# ✅ Recommended minimal permissions
permissions:
  contents: read
  actions: read
  security-events: write
  
# ❌ Avoid broad permissions
permissions: write-all
```

#### ✅ GITHUB_TOKEN Security
- [ ] **Limit token scope**: Use the most restrictive scope possible
- [ ] **Rotate tokens regularly**: Implement automatic token rotation
- [ ] **Monitor token usage**: Track and audit token access patterns

### 🔐 Dependency Security

#### ✅ Action Version Pinning
- [ ] **Pin to specific SHA**: Use full commit SHA instead of version tags
- [ ] **Regularly update pinned versions**: Monthly security review of action versions
- [ ] **Validate action sources**: Only use actions from trusted publishers

```yaml
# ✅ Good - Pinned to specific SHA
- uses: actions/checkout@8ade135a41bc03ea155e62e844d188df1ea18608

# ❌ Risky - Using mutable tags
- uses: actions/checkout@v4
- uses: actions/checkout@main
```

#### ✅ Dependency Auditing
- [ ] **Run npm audit**: Automatically check for known vulnerabilities
- [ ] **Use Dependabot**: Enable automated dependency updates
- [ ] **Implement SBOM generation**: Create Software Bill of Materials for tracking
- [ ] **Regular security scans**: Weekly vulnerability assessments

### ⚡ Workflow Trigger Security

#### ✅ Trigger Restrictions
- [ ] **Limit pull_request triggers**: Use `pull_request_target` carefully
- [ ] **Restrict fork contributions**: Require approval for external contributors
- [ ] **Validate trigger sources**: Verify workflow triggers are legitimate

```yaml
# ✅ Secure trigger configuration
on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]
    types: [ opened, synchronize, reopened ]
  schedule:
    - cron: '0 6 * * 1'  # Monday at 6 AM UTC
```

#### ✅ Branch Protection
- [ ] **Enable branch protection**: Require PR reviews for main branches
- [ ] **Require status checks**: Mandate security scans before merging
- [ ] **Restrict force pushes**: Prevent history rewriting on protected branches

### 📦 Artifact Handling Security

#### ✅ Artifact Management
- [ ] **Encrypt sensitive artifacts**: Use GPG encryption for sensitive data
- [ ] **Limit artifact retention**: Set appropriate retention periods (30-90 days)
- [ ] **Validate artifact integrity**: Use checksums to verify artifact integrity
- [ ] **Restrict artifact access**: Control who can download artifacts

```yaml
# ✅ Secure artifact upload
- name: Upload secure artifact
  uses: actions/upload-artifact@65462800fd760344b1a7b4382951275a0abb4808
  with:
    name: secure-report-${{ github.sha }}
    path: reports/security-scan.json
    retention-days: 30
```

### 🖥️ Codespace Configuration Security

#### ✅ Codespace Settings
- [ ] **Restrict Codespace creation**: Limit to organization members only
- [ ] **Configure timeout policies**: Set automatic timeout for inactive Codespaces
- [ ] **Implement resource limits**: Restrict CPU, memory, and storage usage
- [ ] **Enable audit logging**: Track Codespace creation and usage

#### ✅ Development Environment Security
```json
// .devcontainer/devcontainer.json security configuration
{
  "name": "Secure NEWS Development",
  "image": "mcr.microsoft.com/devcontainers/javascript-node:18",
  "features": {
    "ghcr.io/devcontainers/features/git:1": {},
    "ghcr.io/devcontainers/features/github-cli:1": {}
  },
  "customizations": {
    "vscode": {
      "settings": {
        "security.workspace.trust.enabled": true,
        "git.autofetch": false,
        "extensions.autoUpdate": false
      }
    }
  },
  "remoteUser": "node",
  "runArgs": ["--security-opt", "seccomp=unconfined"]
}
```

### 📊 Monitoring and Alerts

#### ✅ Security Monitoring
- [ ] **Enable security alerts**: Configure GitHub security advisories
- [ ] **Implement audit logging**: Track all security-relevant events
- [ ] **Set up alerting**: Configure notifications for security events
- [ ] **Regular security reviews**: Monthly security posture assessments

#### ✅ Incident Response
- [ ] **Define incident procedures**: Clear steps for security incidents
- [ ] **Implement emergency contacts**: 24/7 security team contacts
- [ ] **Create rollback procedures**: Quick rollback for security issues
- [ ] **Document lessons learned**: Post-incident security improvements

## 🚀 Implementation Priority

### Phase 1: Critical Security (Week 1)
1. ✅ Implement workflow permissions hardening
2. ✅ Pin all action versions to specific SHAs
3. ✅ Configure secret management best practices
4. ✅ Enable branch protection rules

### Phase 2: Enhanced Security (Week 2)
1. ✅ Implement dependency auditing
2. ✅ Configure artifact security
3. ✅ Set up security monitoring
4. ✅ Implement Codespace restrictions

### Phase 3: Advanced Security (Week 3)
1. ✅ Deploy comprehensive monitoring
2. ✅ Implement incident response procedures
3. ✅ Conduct security training
4. ✅ Regular security audits

## 🔍 Validation Steps

### Pre-Implementation Validation
1. **Security Baseline Assessment**
   ```bash
   # Run security audit
   npm audit --audit-level moderate
   
   # Check for known vulnerabilities
   npm audit fix
   
   # Validate workflow syntax
   cd .github/workflows
   for file in *.yml; do
     echo "Validating $file"
     cat "$file" | grep -E "(permissions|secrets|uses)" || true
   done
   ```

### Post-Implementation Validation
1. **Security Configuration Verification**
   ```bash
   # Verify permissions are minimal
   grep -r "permissions:" .github/workflows/
   
   # Check action pinning
   grep -r "uses:" .github/workflows/ | grep -v "@[a-f0-9]{40}"
   
   # Validate secret usage
   grep -r "secrets\." .github/workflows/
   ```

## 📚 Additional Resources

- [GitHub Actions Security Best Practices](https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions)
- [Codespaces Security Documentation](https://docs.github.com/en/codespaces/managing-your-codespaces/managing-repository-access-for-your-codespaces)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
- [OWASP Security Guidelines](https://owasp.org/www-project-top-ten/)

## 🆘 Emergency Contacts

- **Security Team Lead**: security@news-platform.local
- **DevOps Engineer**: devops@news-platform.local  
- **24/7 Security Hotline**: +1-800-SEC-HELP

---

**Last Updated**: December 2024  
**Review Cycle**: Quarterly  
**Next Review**: March 2025

> 💡 **Note**: This guide should be reviewed and updated quarterly to incorporate new security threats and best practices.