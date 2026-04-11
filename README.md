# SLC IITM Website - Comprehensive Specification Document

## Executive Summary

A centralized digital platform for the Student Legislative Council (SLC) of IIT Madras to streamline budget management, session documentation, manifesto tracking, and legislative processes. The portal addresses critical inefficiencies in budget tracking, document management, and transparency while providing role-based access to stakeholders.

---

## 1. Problem Statement & Current Issues

### 1.1 Budget Management Challenges
- **Delayed Budget Sessions**: Head of Secretariat (HoS) struggles with finding and updating budget sheets
- **Multiple Sheet Chaos**: Lack of version control; difficulty in identifying the correct/latest budget sheet
- **No Centralization**: No single source of truth for budget data
- **Calculation Errors**: Manual calculations leading to frequent mistakes
- **No Historical Comparison**: Inability to compare current budgets with previous years for the same events
- **Limited GSB Oversight**: General Student Body cannot directly question or suggest changes despite funding coming from student fees
- **Team Member Tracking Issues**: Difficult to verify actual team sizes, leading to potential fraud in T-shirt orders, team treats, etc. *(Can be addressed in future improvements)*

### 1.2 Session Documentation Problems
- **Delayed MoM/ToD**: Minutes of Meeting and Terms of Discussion are manually created, causing delays
- **Manual Transcription**: No automated tools for generating documentation from recordings
- **Document Drafting**: No standardized platform for creating bills, resolutions, and drafts

### 1.3 Accountability Gaps
- **Manifesto Tracking**: No systematic way to track Executive Council manifesto promises
- **Progress Updates**: Inconsistent monthly updates to Standing Committees
- **GSB Visibility**: Students cannot easily monitor progress on electoral promises

---

## 2. Access Control & User Hierarchy

### 2.1 User Roles (Top to Bottom)

| Role | Access Level | Permissions |
|------|--------------|-------------|
| **Speaker** | Highest | Full edit access to all budget sheets, documents, and settings; Can initiate voting; Approve budget update windows |
| **Head of Secretariat (HoS)** | Administrative | Edit budget sheets for ALL spheres; Approve budget update windows; Manage sphere-level data |
| **Standing Committee** | Sphere-specific | Edit budget sheets ONLY for their assigned sphere; Approve/decline EC change requests; View all published documents |
| **Executive Council (EC)** | Contributory | View unpublished budgets; Request changes (add/edit rows, columns, events, upload sheets); Update manifesto progress; Cannot directly edit |
| **Legislators** | Legislative | Vote on proposals; View all published budgets and documents; Access meeting records; Comment on proposals |
| **General Student Body (GSB)** | Public View | View all published budget sheets, approved documents, team lists, and reports; Cannot edit or vote |
| **Unapproved/Guest** | Minimal | Access only to homepage; View basic information about SLC |

### 2.2 Authentication & Security
- **Institute Email-based Login**: Authentication via IITM email addresses
- **Role Assignment**: Manual role assignment by Speaker/admin based on official positions
- **Session Management**: Secure session tokens, automatic logout after inactivity
- **Audit Logging**: All changes logged with timestamp, user ID, and action type
- **Two-Factor Authentication**: Optional 2FA for Speaker and HoS roles

---

## 3. Website Structure & Pages

### 3.1 Homepage

#### Hero Section
- **Left Side**: 3-4 lines defining SLC's mission and role
  - Example: "The Student Legislative Council is the apex democratic body representing the student community of IIT Madras. We legislate policies, manage budgets exceeding ₹XX lakhs, and ensure transparent governance for 10,000+ students."
- **Right Side**: Representative image/photo showcasing SLC (session in progress, council meeting, etc.)

#### Messages Section
- **Dean of Students**: Brief message/quote with photo
- **Director**: Welcome note with photo
- **Faculty Advisor**: Guidance message with photo
- **Current Speaker**: Address to student body with photo

#### Quick Stats Dashboard
- Total budget allocated (current year)
- Number of events conducted
- Active proposals
- Upcoming sessions

#### Recent Activities
- **Latest SLC Sessions**: Date, agenda, status (completed/upcoming)
- **Recent Events**: Events funded/organized by SLC
- **Standing Committee Updates**: Brief highlights from each committee

#### What is SLC? Section
- **Purpose & Functions**: Overview of SLC's role
- **Legislative Process**: How bills are passed
- **Budget Allocation**: How student fees are utilized
- **Contact Information**: How students can reach out

#### News & Announcements
- Scrolling ticker or card-based layout for recent announcements
- Filter by category: Urgent, General, Opportunities, Events

---

### 3.2 Team Page

Organized hierarchically with photos, names, positions, and contact details:

#### 3.2.1 Leadership
- **Speaker**: Name, photo, email, LinkedIn, manifesto (if applicable)
- **Deputy Speaker**: Same details

#### 3.2.2 Secretariat Team
- **Secretary (each sphere)**: Academic, Cultural, Sports, Technical, etc.
- Contact details and brief role description

#### 3.2.3 Public Policy Club (PPC)
- Members list with roles
- Responsibilities overview

#### 3.2.4 Standing Committees
Organized by sphere:
- **Committee Name** (e.g., Academic Affairs Committee)
  - Chairperson
  - Members
  - EC Representative assigned to this sphere
  - Contact email for the committee

#### 3.2.5 Legislators
- Grid/list view of all legislators
- Filter by hostel/constituency
- Profile: Name, photo, constituency, email, attendance record (optional)

#### 3.2.6 Executive Council
- President, Vice Presidents, General Secretaries
- Manifesto link
- Progress tracker link (redirects to manifesto tracking page)

#### Additional Features
- **Search Functionality**: Find team members by name or role
- **Downloadable Contacts**: Export team contact list as CSV/PDF (Only available to Legislators, Speaker, HoS, and Executive Council)
- **Term Archive**: View previous SLC teams (dropdown by year)

---

### 3.3 Budget Sheet Section

This is the core feature addressing budget management issues.

#### 3.3.1 Budget Navigation Structure

**Level 1: Year Selection**
- Buttons for years: **Current (2026)**, **2025**, **2024**, **2023** (expandable)
- Default: Current year
- Quick comparison view: "Compare with Previous Year" toggle

**Level 2: Semester Selection**
- **Odd Semester** (July-November)
- **Even Semester** (January-May)
- **Annual Events** (full-year budget)

**Level 3: Sphere View**
- Table displaying all spheres with columns:
  - Sphere Name
  - Total Allocated Budget
  - Total Spent (manually updated)
  - Remaining Budget
  - % Utilized
  - Status (Under Budget / Over Budget / On Track)
  - Quick Actions (View Details, Download Report)

*Note: Real-time budget tracking can be proposed as a future improvement requiring integration with finance systems.*

**Level 4: Team-wise Budget (within a sphere)**
- Click on any sphere → Opens detailed view
- Table with columns:
  - Team/Club Name
  - Total Allocated
  - Spent
  - Remaining
  - Number of Events
  - Quick Actions (View Events, Edit, Request Change)

**Level 5: Event-wise Budget (within a team)**
- Click on any team → Opens event-level detail
- Table with columns:
  - Event Name
  - Date
  - Allocated Budget
  - Actual Spent
  - Category (Venue, Food, Marketing, Prizes, etc.)
  - Team Size
  - Variance (± from budget)
  - Supporting Documents (upload receipts, bills if needed)
  - Comments/Notes

#### 3.3.2 Budget Sheet Features

**A. Edit Permissions (Role-based)**
- **Speaker/HoS**: Can edit any cell, add/delete rows, approve changes
- **Standing Committee**: Can edit only their sphere's budget; approve EC requests
- **Executive Council**: Cannot directly edit; can submit change requests with justification
- **View-only**: GSB and Legislators can view but not edit

**B. Change Request System (for EC)**
When EC wants to modify budget:
1. Click "Request Change" button
2. Choose change type:
   - Add new event
   - Modify existing event budget
   - Add expense category
   - Upload revised Excel sheet
3. Fill form:
   - Event/Item name
   - Current budget (if modifying)
   - Requested budget
   - Justification (text field, min 50 words)
   - Supporting documents (upload)
4. Submit to Standing Committee
5. **Standing Committee Action** (based on Speaker's settings):
   - **Option A (Approval Required)**: Standing Committee must Approve/Decline with comments before changes take effect
   - **Option B (Inform Only)**: Standing Committee can directly update budget sheet; Speaker/HoS is notified of changes but approval is not required
6. If approval required and declined → EC gets notification with reason
7. Speaker can toggle between these modes in settings

**C. Budget Update Window & Standing Committee Permissions**
- **Lock/Unlock Toggle** (Speaker/HoS only)
- **Approval Mode Toggle** (Speaker only):
  - "Require Approval": Standing Committee changes need Speaker/HoS approval
  - "Direct Update": Standing Committee can directly edit without approval (Speaker/HoS receives notification only)
- Before Budget Session: Standing Committees can add/edit budgets when unlocked
- During Session: Budget is locked (read-only except for Speaker)
- After Session: Locked for allocation; unlocked for expense tracking

**D. Change Log & Audit Trail**
- Every edit is logged with:
  - Timestamp (exact date & time)
  - User who made the change
  - What changed (old value → new value)
  - Reason for change (optional comment field)
- Accessible to Legislators and above
- Exportable as PDF report
- Filter by: Date range, User, Sphere, Event

**E. Historical Comparison Tool**
- "Compare with Last Year" button at event level
- Shows side-by-side comparison:
  - Previous year's budget for same event
  - Current year's budget
  - % increase/decrease
  - Justification for change (optional)

*Note: Team member verification for preventing T-shirt/treat fraud can be implemented as a future improvement with proper registration integration.*

**F. Summarize Feature**
- **AI-powered summary button** at every level:
  - Sphere level: "Total spending across all teams, major events, budget health"
  - Team level: "Key events, spending trends, comparison with last year"
  - Event level: "Breakdown of expenses, invoice status, variance explanation"
- Generated summary appears in popup/sidebar
- Downloadable as PDF

**H. Export & Download Options**
- Download individual budget sheet as Excel/PDF
- Generate full budget report (all spheres, consolidated)
- Custom reports: Filter by date range, sphere, spending category

*Note: Invoice and receipt management is out of scope for SLC and can be handled by finance department separately.*

---

### 3.4 Documents Section

#### 3.4.1 Document Library
**Categories:**
- **Bills**: Proposed legislation
- **Resolutions**: Non-legislative decisions
- **Reports**: Committee reports, session minutes
- **Agendas**: Upcoming session agendas
- **Minutes of Meeting (MoM)**: Official session records
- **Terms of Discussion (ToD)**: Discussion summaries
- **Policies**: Approved policies and guidelines
- **Archived**: Historical documents (by year/session)

**Sorting & Filtering:**
- By SLC session number (default: current SLC term)
- By date (newest first)
- By status: Draft, Under Review, Approved, Rejected, Archived
- By category
- Search by keyword

#### 3.4.2 Document Creation & Editing

**Built-in Document Editor:**
- Rich text editor (similar to Google Docs)
- Features:
  - Formatting: Bold, italics, headings, lists, tables
  - Collaboration: Real-time multi-user editing (for authorized roles)
  - Comments: Add comments/suggestions (visible to Standing Committee+)
  - Version history: Track all changes
  - Templates: Pre-built templates for bills, resolutions, agendas
  - Auto-numbering: Clause/section numbering
  - Export: Download as DOCX/PDF

**Creating New Agenda:**
1. Click "Create New Agenda" (Speaker/HoS/Standing Committee only)
2. Select template: Regular Session, Budget Session, Special Session
3. Fill in:
   - Session number
   - Date & time
   - Venue
   - Items for discussion (drag-and-drop to reorder)
   - Expected duration
4. Attach related documents (previous MoM, pending bills)
5. Save as draft or publish
6. Auto-notify all legislators via email

**Editing Agendas:**
- Editable until session starts
- Once session begins → Locked (read-only)
- After session → Generate MoM/ToD from this agenda

#### 3.4.3 Document Approval Workflow

**Draft → Review → Approve → Publish**

1. **Draft Stage** (EC/Standing Committee):
   - Create document
   - Collaborate with team
   - Save drafts (auto-save every 2 mins)

2. **Review Stage** (Standing Committee/Speaker):
   - Submit for review
   - Reviewers can add comments
   - Request changes (sent back to draft)

3. **Approval Stage** (Speaker/HoS):
   - Final approval required
   - Can reject with reason
   - Can approve with amendments

4. **Published Stage**:
   - Document locked (no further edits)
   - Visible to all based on access level
   - Notification sent to relevant parties

#### 3.4.4 Document Permissions
- **Create**: Speaker, HoS, Standing Committee
- **Edit Draft**: Creator + collaborators
- **Review**: Standing Committee, Speaker
- **Approve**: Speaker, HoS
- **View Published**: All users based on document sensitivity
- **Comment**: Legislators and above

---

### 3.5 Voting Page

#### 3.5.1 Voting Dashboard
- **Active Votes**: Ongoing voting sessions
- **Upcoming Votes**: Scheduled votes
- **Past Votes**: Historical voting records with results
- **My Voting History**: Personal record (for Legislators)

#### 3.5.2 Initiating a Vote (Speaker/HoS Only)

**Create New Vote:**
1. Click "Initiate Vote"
2. Fill details:
   - Vote Title (e.g., "Budget Allocation for Tech Fest 2026")
   - Description (brief context)
   - Attach related document (bill/proposal)
   - Vote type: Simple Majority, 2/3rd Majority, Unanimous
   - Duration: End date & time
   - Voting mode: Anonymous / Open
     - **Anonymous**: No one can see individual votes (even Speaker)
     - **Open**: Speaker/HoS can see who voted what + who hasn't voted yet
3. Select eligible voters: All Legislators / Specific group
4. Start vote immediately / Schedule for later

**Notifications:**
- All eligible voters receive email + in-app notification
- Reminders sent at 24 hrs, 6 hrs, 1 hr before deadline

#### 3.5.3 Casting a Vote (Legislators)

**Voting Interface:**
- Proposal title and description displayed prominently
- **Attached Document Preview**: View bill/proposal without leaving page
- Three voting options (large, clearly labeled buttons):
  - ✅ **For** (Green)
  - ❌ **Against** (Red)
  - ⚪ **Abstain** (Gray)
- Optional: Comment/justification box (200 words max)
- **Submit Vote** button
- Confirmation popup: "Your vote has been recorded. You cannot change it."

**Voting Rules:**
- One vote per legislator per proposal
- Cannot change vote once submitted
- Voting open until deadline
- If no vote cast by deadline → Counted as abstention (optional behavior)

#### 3.5.4 Vote Tracking (Speaker/HoS Only)

**Real-time Dashboard (Only for Speaker/HoS):**
- Total votes cast / Total eligible voters
- Breakdown: For (X%), Against (Y%), Abstain (Z%)
- **Who Voted**: List of legislators who have voted
  - **In Open Mode**: Names + their voting choice (For/Against/Abstain)
  - **In Anonymous Mode**: Only names of who voted (not their choice)
- **Who Hasn't Voted**: List of pending voters with "Send Reminder" button
- Visual chart: Pie/bar chart showing distribution

**For Other Users (Legislators, EC, Standing Committee, GSB):**
- Can only see aggregate statistics:
  - Total votes cast vs Total eligible
  - Percentage breakdown (For/Against/Abstain)
  - Cannot see individual voting choices
  - Cannot see who has/hasn't voted yet

#### 3.5.5 Vote Results

**After Voting Closes:**
- Automatic calculation of result:
  - **Passed**: If meets required majority
  - **Rejected**: If doesn't meet threshold
  - **Tied**: If exactly 50-50 (Speaker's casting vote)
- Result announcement email sent to all legislators
- Result displayed on voting page with:
  - Final tally (aggregate numbers)
  - Outcome (Passed/Rejected)
  - Date & time of closure
  - Next steps (if applicable)

**Result Visibility:**
- **Open Votes**: 
  - Speaker/HoS can see full breakdown (who voted what)
  - All other users see only aggregate results (total For/Against/Abstain)
- **Anonymous Votes**: 
  - Only aggregate results visible to everyone (including Speaker/HoS)
  - No individual voting data accessible to anyone

#### 3.5.6 Voting Analytics (for Speaker/HoS)
- Average voting participation rate
- Most active/inactive legislators
- Historical trends (pass/rejection rates)
- Download voting report (CSV/PDF)

---

### 3.6 Reports Section

**Purpose**: Centralized repository for all SLC reports, sortable and filterable.

#### 3.6.1 Report Categories
- **Session Reports**: Summary of each SLC session (MoM, ToD)
- **Budget Reports**: Semester-wise and annual budget utilization
- **Standing Committee Reports**: Monthly/semester reports from each committee
- **Event Reports**: Post-event reports from ECs
- **Annual Reports**: Comprehensive yearly report

#### 3.6.2 Navigation
**Default View**: Current SLC term (2025-26)

**Filters:**
- By SLC term: 2025-26, 2024-25, 2023-24 (dropdown)
- By semester: Odd/Even
- By category: Session, Budget, Committee, Event
- By date range
- Search by keyword

#### 3.6.3 Report Display
- **List View**: Title, Date, Category, Author, Download button
- **Grid View**: Card-based layout with thumbnail/icon
- Click to open → Preview in browser (PDF/HTML)
- Download as PDF/DOCX

#### 3.6.4 Voice-to-Text Generator for ToD (Terms of Discussion)

**Purpose**: Convert session audio recordings to text for easier ToD creation.

**Workflow:**
1. **Upload Recording**: SLC team uploads session audio/video file
   - Supported formats: MP4, MP3, WAV, M4A
   - Max size: 2GB
   
2. **Automatic Transcription**: 
   - AI-powered speech-to-text conversion
   - Generates timestamped transcript
   - Speaker identification (if multiple speakers)
   
3. **Review & Edit**:
   - Coordinators review the auto-generated transcript
   - Edit for accuracy (fix names, technical terms, etc.)
   - Add section headings for different agenda items
   - Highlight key decisions and action items
   
4. **Generate ToD**:
   - Extract key discussion points from transcript
   - Organize by agenda items
   - Add decisions made and action items
   - Format into standard ToD template
   
5. **Approval & Publishing**:
   - Submit for Standing Committee/Speaker review
   - Make final edits
   - Publish to Reports section
   - Notify all legislators

**Features:**
- **Search within Transcript**: Find specific topics/words discussed
- **Export Options**: Download transcript as TXT/PDF/DOCX
- **Timestamp Links**: Click on timestamp to jump to that point in audio (if audio is also uploaded)
- **Collaborative Editing**: Multiple coordinators can edit simultaneously

---

### 3.7 Manifesto Tracker (EC Progress Monitoring)

**Purpose**: Track Executive Council's campaign promises and their implementation status.

#### 3.7.1 Manifesto Overview Page
- **EC Member-wise Manifestos**: Each EC's campaign promises
  - President
  - VP (Academic/Students)
  - General Secretaries (Cultural/Sports/Technical/etc.)
- Select EC → View their manifesto points

#### 3.7.2 Manifesto Points Structure
Each promise/point includes:
- **Title**: Brief description (e.g., "Improve mess food quality")
- **Category**: Academic, Welfare, Infrastructure, Cultural, Sports, etc.
- **Timeline**: Expected completion date
- **Status**: 
  - 🔴 Not Started
  - 🟡 In Progress
  - 🟢 Completed
  - ⚫ Dropped (with reason)
- **Progress Percentage**: 0-100%
- **Description**: Detailed explanation of what was promised
- **Updates**: Monthly update log (What was done, challenges faced, next steps)
- **Evidence**: Photos, documents, links proving completion

#### 3.7.3 Monthly Update Process
1. **Reminder Sent**: Auto-reminder to EC 5 days before Standing Committee meeting
2. **EC Updates**: EC logs into portal, updates their manifesto points:
   - Change status
   - Add progress notes
   - Upload evidence
3. **Standing Committee Review**: Each Standing Committee reviews updates related to their sphere
4. **Standing Committee Report**: Committee compiles report, sends to Speaker
5. **GSB Visibility**: Updated manifesto tracker visible to all students

#### 3.7.4 Tracking Dashboard (for GSB)
- **Overall Progress**: Aggregate % of promises completed
- **Filter by EC**: See specific EC member's progress
- **Filter by Category**: Academic, Welfare, etc.
- **Filter by Status**: Show only completed/in-progress/not started
- **Timeline View**: Gantt chart showing when promises are due
- **Comparison**: Compare current EC with previous ECs (if data available)

#### 3.7.5 Accountability Features
- **Public Comments**: GSB can comment on each manifesto point (moderated)
- **Feedback/Suggestions**: Students can give feedback on implementation
- **Alerts**: If a promise is overdue, highlight in red
- **Email Updates**: Students can subscribe to get monthly manifesto updates

---

### 3.8 AI Chatbot (Persistent Across All Pages)

**Purpose**: Provide instant help, answer queries, and guide users through the portal.

#### 3.8.1 Chatbot Features
- **Fixed Position**: Bottom-right corner popup icon
- **Expandable**: Click to open chat window
- **Persistent**: Available on every page
- **Context-Aware**: Knows which page user is on

#### 3.8.2 Capabilities
**General Queries:**
- "What is SLC?"
- "How do I contact the Academic Secretary?"
- "When is the next SLC session?"
- "What events are happening this month?"

**Budget Queries:**
- "What is the budget for Tech Fest?"
- "How much has the Cultural Sphere spent this semester?"
- "Show me budget comparison for Saarang 2025 vs 2024"
- "Which team has the highest budget allocation?"

**Document Queries:**
- "Show me the latest MoM"
- "Find bills related to hostel policies"
- "What resolutions were passed last month?"

**Manifesto Queries:**
- "What is the progress on mess food improvement?"
- "Show me the President's manifesto"
- "Which promises are completed?"

**Navigation Help:**
- "How do I vote on a proposal?"
- "Where can I see the budget sheet?"
- "How do I request a budget change?"

#### 3.8.3 Technical Implementation
- **AI Model**: Claude API or similar LLM
- **Knowledge Base**: Trained on SLC documents, FAQs, budget data
- **Natural Language Processing**: Understands questions in plain English
- **Fallback**: If chatbot can't answer → "Please contact [relevant person/email]"
- **Feedback Loop**: "Was this answer helpful?" → Improve responses over time

#### 3.8.4 Chatbot Design
- Modern, friendly UI
- Quick reply suggestions (buttons for common questions)
- Typing indicator
- Message history (within session)
- Clear/reset chat option

---

## 4. Additional Features & Enhancements

### 4.1 Notifications System
- **In-app Notifications**: Bell icon in header with dropdown
- **Email Notifications**: For important events
- **SMS/WhatsApp** (Optional): For urgent matters

**Notification Types:**
- Budget change request status
- Voting reminders
- New document published
- Session schedule updates
- Manifesto updates
- Deadline reminders

### 4.2 Search Functionality (Global)
- Search bar in header
- Searches across:
  - Team members
  - Budget items
  - Documents
  - Manifesto points
  - Reports
- Auto-suggestions as user types
- Filter results by category

### 4.3 Mobile Responsiveness
- Fully responsive design (works on phones, tablets)
- Touch-friendly buttons and navigation
- Simplified mobile view for complex tables (budget sheets)
- Progressive Web App (PWA) features:
  - Install on home screen
  - Offline access to cached data
  - Push notifications

### 4.4 Accessibility
- **WCAG 2.1 AA Compliance**:
  - Screen reader friendly
  - Keyboard navigation support
  - High contrast mode
  - Text size adjustment
  - Alt text for all images

### 4.5 Analytics & Insights (Admin Panel)
- **User Activity**: Page views, most visited sections
- **Budget Insights**: Spending trends, variance analysis
- **Engagement Metrics**: Voting participation, document downloads
- **Chatbot Analytics**: Most asked questions, unresolved queries

### 4.6 Integrations
- **Google Workspace**: SSO login, Calendar integration
- **Email Service**: SendGrid/Mailgun for notifications
- **Cloud Storage**: Google Drive/AWS S3 for document storage
- **Payment Gateway** (Future): For event registrations

### 4.7 Feedback & Support
- **Feedback Form**: On every page (footer)
- **Report a Bug**: Technical issues reporting
- **Suggestion Box**: Feature requests from users
- **Help Center**: FAQs, video tutorials, user guides

### 4.8 Data Export & Backup
- **Daily Backups**: Automated database backups
- **Export All Data**: Admin can export entire database
- **Version Control**: Use Git for code, version control for documents

---

## 5. Technical Architecture (High-Level)

### 5.1 Tech Stack Recommendations

**Frontend:**
- React.js / Next.js (for dynamic UI)
- Tailwind CSS / Material-UI (for styling)
- Chart.js / Recharts (for data visualization)

**Backend:**
- Node.js + Express.js / Django / Flask
- RESTful API or GraphQL

**Database:**
- PostgreSQL (relational data: users, budgets, documents)
- MongoDB (optional, for logs and unstructured data)

**Authentication:**
- OAuth 2.0 / JWT tokens
- Integration with IITM SSO

**File Storage:**
- AWS S3 / Google Cloud Storage (for documents, invoices, recordings)

**AI/ML:**
- Anthropic Claude API (for chatbot)
- Whisper API / Google Speech-to-Text (for transcription)

**Hosting:**
- AWS / Google Cloud / Azure
- CDN for faster content delivery

**Version Control:**
- GitHub / GitLab

---

## 6. Implementation Roadmap

### Phase 1 (MVP - 2 months)
- User authentication & role management
- Homepage + Team page
- Basic budget sheet viewing (read-only for GSB)
- Document library (view only)
- Simple voting page (manual vote initiation)

### Phase 2 (3 months)
- Budget editing permissions & change request system
- Audit trail & change logs
- Document editor & approval workflow
- Automated MoM/ToD generation (AI transcription)
- Manifesto tracker

### Phase 3 (2 months)
- AI chatbot integration
- Advanced analytics & reporting
- Mobile app (React Native)
- Notifications system (email + in-app)
- Search functionality

### Phase 4 (Ongoing)
- User feedback implementation
- Performance optimization
- Security audits
- Feature enhancements based on usage

---

## 7. Success Metrics

### 7.1 Efficiency Gains
- **Budget Session Preparation Time**: Reduce from X days to Y days
- **ToD Generation Time**: From manual 3-5 days to AI-assisted 1 day (with voice-to-text)
- **Budget Error Rate**: Reduce calculation errors by 90%
- **Document Turnaround**: Publish session documents within 48 hours

### 7.2 User Engagement
- **GSB Engagement**: X% of students actively viewing budgets
- **Voting Participation**: Increase legislator voting rate to >90%
- **Manifesto Tracking**: X views per month

### 7.3 Transparency
- **Audit Trail**: 100% traceability of budget changes with timestamp and user logs
- **Document Accessibility**: All documents available within 24-48 hrs of session
- **Budget Visibility**: Real-time access to all published budget sheets for GSB

### 7.4 Future Improvements
- Real-time budget tracking with finance system integration
- Team member verification system for fraud prevention
- Invoice management workflow
- Advanced analytics and predictive budgeting

---

## 8. Security & Privacy Considerations

### 8.1 Data Protection
- **Encryption**: All data encrypted at rest and in transit (SSL/TLS)
- **Access Logs**: Who accessed what, when
- **GDPR/Data Privacy Compliance**: User data handling policies

### 8.2 Security Measures
- **Rate Limiting**: Prevent DDoS attacks
- **SQL Injection Protection**: Parameterized queries
- **XSS Protection**: Sanitize all user inputs
- **Regular Security Audits**: Quarterly penetration testing

### 8.3 Backup & Recovery
- **Daily Automated Backups**: Database + files
- **Disaster Recovery Plan**: Restore from backup within 1 hour
- **Redundancy**: Multiple server instances

---

## 9. Maintenance & Support

### 9.1 Ongoing Maintenance
- **Bug Fixes**: Monthly release cycle
- **Feature Updates**: Quarterly major updates
- **Performance Monitoring**: 24/7 uptime monitoring

### 9.2 User Support
- **Helpdesk**: Email support (response within 24 hrs)
- **Training Sessions**: For new SLC members each year
- **Documentation**: User manuals, video tutorials

---

## 10. Cost Estimation (Rough)

| Component | Estimated Cost (Annual) |
|-----------|-------------------------|
| Cloud Hosting (AWS/GCP) | ₹50,000 - ₹1,00,000 |
| Domain & SSL | ₹5,000 |
| AI API (Chatbot + Transcription) | ₹20,000 - ₹50,000 |
| Email Service | ₹10,000 |
| Development (if outsourced) | ₹2,00,000 - ₹5,00,000 (one-time) |
| Maintenance | ₹50,000 - ₹1,00,000 |
| **Total (Year 1)** | **₹3,35,000 - ₹7,55,000** |

*Note: If developed in-house by students, development cost can be significantly reduced.*

---

## Conclusion

This comprehensive portal will transform SLC operations by:
1. **Centralizing Data**: Single source of truth for budgets, documents, and manifesto tracking
2. **Improving Efficiency**: Automated voice-to-text for ToD generation, streamlined workflows reduce manual effort and errors
3. **Enhancing Transparency**: GSB can monitor budgets and EC progress; detailed change logs for accountability
4. **Strengthening Accountability**: Audit trails and manifesto tracking ensure responsibility
5. **Modernizing Governance**: AI-powered tools (chatbot, summarization, transcription) make SLC more accessible and responsive
6. **Flexible Workflows**: Speaker-configurable approval modes for Standing Committee budget updates

The platform is scalable, secure, and designed to evolve with SLC's needs. Future enhancements can include real-time budget tracking, team verification systems, and invoice management integration. With proper implementation and user adoption, this portal will set a new standard for student governance at IIT Madras.

---

**Document Version**: 1.0  
**Last Updated**: April 11, 2026  
**Prepared By**: Claude (Anthropic AI)  
**For**: SLC IITM Website Project
