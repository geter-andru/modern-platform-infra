# Staging Test Procedures - hs-platform

## 🚀 **Staging Environment Details**

### **URLs**
- **Production (Current)**: `https://platform.andru-ai.com` (assets-app)
- **Staging (New)**: `https://deploy-preview-[BUILD-NUMBER]--platform-andru-ai.netlify.app` (hs-platform)
- **Expected Pattern**: `https://deploy-preview-*--platform-andru-ai.netlify.app`

### **Build Information**
- **Branch**: `assets-feature`
- **Framework**: Next.js 15 (Static Export)
- **Build Command**: `npm run build` from `hs-platform/frontend/`
- **Deploy Directory**: `hs-platform/frontend/out/`

---

## **🧪 Testing Protocol**

### **Phase 1: Deployment Verification (5 minutes)**

1. **Check Netlify Build Status**
   - Go to Netlify dashboard
   - Verify `assets-feature` branch deployed successfully
   - Note the staging URL provided

2. **Basic Connectivity Test**
   ```bash
   # Replace URL with actual staging URL
   curl -I https://deploy-preview-X--platform-andru-ai.netlify.app
   # Should return: HTTP/2 200
   ```

3. **Initial Page Load**
   - Open staging URL in browser
   - Verify page loads without errors
   - Check browser console for JavaScript errors

### **Phase 2: Core Functionality Tests (15 minutes)**

#### **Customer Access Tests**
1. **Admin Customer Test**
   ```
   URL: https://staging-url/customer/CUST_4?token=admin-demo-token-2025
   Expected: Dashboard loads with admin features
   ```

2. **Test Customer Access**
   ```
   URL: https://staging-url/customer/CUST_02?token=test-token-123456
   Expected: Customer dashboard loads
   ```

3. **Invalid Token Test**
   ```
   URL: https://staging-url/customer/CUST_4?token=invalid
   Expected: Appropriate error handling
   ```

#### **Navigation Tests**
1. **Home Page**: Root URL loads correctly
2. **Dashboard**: `/dashboard` accessible
3. **ICP Tool**: `/icp` or tool navigation works
4. **Cost Calculator**: Tool accessible via navigation
5. **Business Case**: Tool accessible and functional

#### **Tool Functionality Tests**
1. **ICP Analysis**
   - Form loads and accepts input
   - Submit button functional
   - Results display correctly

2. **Cost Calculator**
   - Input fields work
   - Calculations execute
   - Results render properly

3. **Business Case Builder**
   - Template selection available
   - Content generation works
   - Export options present

### **Phase 3: Comparison Testing (20 minutes)**

#### **Side-by-Side Verification**
1. **Open both platforms**:
   - Production: `https://platform.andru-ai.com/customer/CUST_4?token=admin-demo-token-2025`
   - Staging: `https://staging-url/customer/CUST_4?token=admin-demo-token-2025`

2. **Compare key elements**:
   - [ ] Same customer data visible
   - [ ] Same navigation structure
   - [ ] Same tools available
   - [ ] Same visual design quality
   - [ ] Similar or better performance

3. **Test key workflows**:
   - [ ] Complete ICP analysis on both
   - [ ] Run cost calculation on both
   - [ ] Generate business case on both
   - [ ] Verify results consistency

### **Phase 4: Mobile & Performance (10 minutes)**

#### **Mobile Responsiveness**
1. **Open staging URL on mobile device**
2. **Test touch navigation**
3. **Verify responsive layouts**
4. **Check mobile-specific features**

#### **Performance Check**
1. **Page Load Speed**: Should be <3 seconds
2. **JavaScript Console**: No critical errors
3. **Network Tab**: Verify resource loading
4. **Lighthouse Score**: Aim for >80

### **Phase 5: Error Handling (10 minutes)**

#### **Error Scenarios**
1. **Invalid URLs**: Test non-existent routes
2. **Network Issues**: Test with throttled connection
3. **Invalid Inputs**: Test form validation
4. **Missing Data**: Test with incomplete data

---

## **📋 Test Results Template**

### **Deployment Verification** ✅/❌
- [ ] Build completed successfully
- [ ] Staging URL accessible
- [ ] Initial page load works
- [ ] No console errors

### **Core Functionality** ✅/❌
- [ ] Customer CUST_4 access works
- [ ] Customer CUST_02 access works
- [ ] Dashboard displays correctly
- [ ] All 3 tools accessible
- [ ] Navigation functional

### **Tool Functionality** ✅/❌
- [ ] ICP Analysis form works
- [ ] Cost Calculator functional
- [ ] Business Case Builder works
- [ ] Export capabilities present
- [ ] Results display correctly

### **Comparison with Production** ✅/❌
- [ ] Same data available
- [ ] Feature parity achieved
- [ ] Visual quality maintained
- [ ] Performance equal/better
- [ ] No functionality missing

### **Mobile & Performance** ✅/❌
- [ ] Mobile responsive
- [ ] Touch interactions work
- [ ] Performance acceptable
- [ ] No critical errors
- [ ] Lighthouse score adequate

### **Overall Assessment**
- **Ready for Production**: ✅/❌
- **Issues Found**: [List any issues]
- **Blockers**: [List any blockers]
- **Recommendations**: [Next steps]

---

## **🚨 Issue Escalation**

### **Severity Levels**

#### **Critical (Block Migration)**
- Customer access completely broken
- Data loading failures
- Security vulnerabilities
- Core tools non-functional

#### **High (Fix Before Migration)**
- Performance significantly worse
- Missing key features
- Mobile experience broken
- Export capabilities broken

#### **Medium (Fix Soon)**
- Minor visual differences
- Non-critical features missing
- Performance slightly worse
- Edge case errors

#### **Low (Fix Later)**
- Cosmetic improvements
- Nice-to-have features
- Minor usability issues
- Documentation updates

### **Escalation Process**
1. **Document issue immediately**
2. **Assign severity level**
3. **Create GitHub issue**
4. **Notify development team**
5. **Track resolution progress**

---

## **✅ Go/No-Go Decision Criteria**

### **GO - Ready for Migration**
- ✅ All critical functionality working
- ✅ Performance equal or better
- ✅ Mobile experience excellent
- ✅ No security vulnerabilities
- ✅ Feature parity achieved
- ✅ Stakeholder approval received

### **NO-GO - Not Ready**
- ❌ Any critical functionality broken
- ❌ Performance significantly worse
- ❌ Security issues identified
- ❌ Major features missing
- ❌ Mobile experience poor
- ❌ Stakeholder concerns raised

---

## **📞 Emergency Contacts**

### **If Critical Issues Found**
1. **Document in GitHub Issues**
2. **Notify development team**
3. **Escalate to project stakeholders**
4. **Consider rollback if in production**

### **Next Steps After Testing**
1. **Complete all test phases**
2. **Document results**
3. **Make go/no-go recommendation**
4. **Plan migration timeline**
5. **Prepare customer communication**

---

## **🎯 Success Criteria**

**Staging is ready for production when:**
- All test phases pass ✅
- No critical or high-severity issues
- Stakeholder approval obtained
- Feature parity checklist completed
- Performance meets or exceeds current
- Customer experience maintained or improved