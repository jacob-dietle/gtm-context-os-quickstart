# GTM Offerings - Domain Ontology

**Version:** 1.0.0
**Created:** November 10, 2025
**Creator:** GTM Fabric Team
**License:** Creative Commons Attribution 4.0

## Overview

This domain ontology defines Go-To-Market offerings including products, services, solutions, and sales offerings. It models information content entities that describe what vendors offer to customers, including product specifications, service descriptions, solution bundles, and sales value propositions.

Following BFO 2020 map-territory distinction, this ontology models information ABOUT offerings (the descriptions, specifications, and value propositions) rather than the actual artifacts or services themselves.

### What is a Sales Offering?

A Sales Offering is the information through which a seller conveys value to customers, codified in solution briefs, case studies, use cases, and collateral. It specifies:

1. **The business problem being solved**
2. **How the seller solves it**
3. **For whom they solve it**
4. **What outcomes are produced**

## Key Architectural Decisions

1. **Offerings are information content entities**, NOT the actual products/services
2. **Map-Territory**: Separate the product (artifact) from information about the product (offering)
3. **Products and Services** are the actual deliverables (artifacts, processes)
4. **Product/Service/Solution Offerings** are information describing what's available
5. **Sales Offerings** are value propositions bundling problem-solution-buyer-outcome

### Pattern Applied

- **Map-Territory**: Product (artifact) vs. ProductOffering (information about product)
- **Information-first**: Sales teams work with offering information, not actual products
- **Composition**: Solutions compose products and services
- **Value articulation**: Sales Offerings articulate business value, not just features

### Module Scope

- **IN SCOPE**: Offering information, value propositions, collateral, problem-solution frameworks
- **OUT OF SCOPE**: Pricing, contracts, product catalogs, inventory (business system concerns)
- **IMPORTS**: BFO 2020, CCO, gtm_organizations
- **IMPORTED BY**: gtm_sales_lifecycle (opportunities reference offerings)

---

## Base Offering Classes

### Offering

**Description:** Information content entity describing what an organization makes available for purchase or subscription.

**Definition:** An information content entity that describes a product, service, solution, or value proposition that an organization makes available to customers. An offering is information ABOUT what can be purchased, including specifications, descriptions, capabilities, and value propositions. This is distinct from the actual artifact (product) or process (service) being delivered.

**Example:** A product offering document describing 'Enterprise CRM Platform' with features, deployment options, integrations, and pricing tiers. The offering is information; the actual CRM software (when deployed) is the artifact.

**Scope Note:** Following BFO map-territory distinction: the Offering is the map (information describing what's available), the actual Product/Service is the territory (the thing delivered). Sales and marketing teams work with offering information to position value to prospects.

---

### Product Offering

**Description:** Information describing a tangible or digital product available for purchase.

**Definition:** An information content entity describing a product (software, hardware, digital asset, or physical good) that an organization offers to customers. Includes product specifications, features, capabilities, versions, editions, deployment models, and technical requirements.

**Example:** Product offering for 'Salesforce Sales Cloud Enterprise Edition' describing features (opportunity management, forecasting, mobile app), deployment (multi-tenant SaaS), integrations (Marketing Cloud, Service Cloud), pricing model (per-user subscription), and technical specs (browser requirements, API limits).

**Scope Note:** Product offerings describe software products, SaaS platforms, hardware appliances, or digital assets. They specify WHAT is delivered, not how it's implemented or supported (those are service offerings).

---

### Service Offering

**Description:** Information describing services (consulting, implementation, support, managed services) available for purchase.

**Definition:** An information content entity describing professional services, implementation services, support services, training, or managed services that an organization offers to customers. Includes service scope, deliverables, timelines, methodologies, and engagement models.

**Example:** Service offering for 'CRM Implementation Services' describing: discovery phase (2 weeks), configuration and customization (6 weeks), data migration (3 weeks), user training (1 week), go-live support (2 weeks), deliverables (implementation plan, configuration documentation, training materials), and engagement model (fixed-price project).

**Scope Note:** Service offerings describe HOW an organization helps customers succeed with products, achieve outcomes, or solve problems through human expertise. Services may be bundled with products in solution offerings.

---

### Solution Offering

**Also known as:** Solution

**Description:** Information describing a combination of products and services configured to address specific customer business outcomes.

**Definition:** An information content entity describing a bundled combination of products, services, configurations, and customizations designed to solve specific customer business problems or achieve particular outcomes. Solutions compose multiple product offerings and service offerings into integrated value propositions, often including custom configurations of vendor products paired with implementation and support services.

**Example:** Solution offering for 'Financial Services Cloud Migration': combines (1) AWS infrastructure products (EC2, RDS, S3, security services), (2) migration services (assessment, architecture design, data migration, testing), (3) training services, (4) 90-day managed support. Configured specifically for regulated financial services with compliance requirements.

**Scope Note:** Solutions are outcome-oriented bundles addressing specific use cases, industries, or business problems. A solution offering is more than the sum of its parts—it articulates how components work together to achieve business value. Solutions often involve custom configurations, industry-specific features, and specialized implementation approaches.

---

### Sales Offering

**Description:** Information content entity through which a seller conveys the complete value proposition to prospective or existing customers.

**Definition:** An information content entity that articulates the complete value proposition a seller delivers to customers, composed of:

1. **The business problem** the seller solves
2. **How the seller solves it** (products, services, solutions, technology, approach)
3. **For whom the seller solves it** (industry, business function, role, persona)
4. **What outcomes the solution produces** (value, benefits, impacts, results)

Sales offerings are codified in solution briefs, case studies, use cases, sales collateral, and marketing materials.

**Example:** Sales offering titled 'RevOps Acceleration for SaaS Scale-Ups':
- **Problem:** SaaS companies scaling from $10M to $50M struggle with pipeline visibility, forecast accuracy, and sales process consistency
- **Solution:** Salesforce Revenue Cloud + implementation services + RevOps playbooks + data integration
- **For Whom:** VP Sales and CRO at SaaS companies with 50-200 employees
- **Outcomes:** 30% improvement in forecast accuracy, 25% reduction in sales cycle, unified pipeline visibility. Codified in 8-page solution brief with case studies.

**Scope Note:** Sales offerings are the primary artifacts sales and marketing teams use to articulate value to buyers. They connect business problems to solutions to outcomes in a buyer-centric narrative. While product offerings describe features and service offerings describe deliverables, sales offerings describe business value and transformation.

---

## Sales Offering Components

### Business Problem Specification

**Description:** Information describing the business problem, challenge, need, or pain point that a sales offering addresses.

**Definition:** An information content entity that specifies the business problem, operational challenge, strategic need, or pain point that drives customer purchase decisions. Articulates the current state issues, costs of inaction, competitive pressures, or strategic imperatives that create urgency for change.

**Example:** Business problem: 'Enterprise sales teams lack real-time visibility into pipeline health, resulting in missed forecasts (±20% variance), late-stage deal surprises, and reactive territory planning. Sales leadership spends 15+ hours weekly compiling manual reports from disparate systems, delaying strategic decisions.'

**Scope Note:** Effective problem specifications quantify pain (time wasted, revenue lost, risk exposure) and connect operational issues to strategic consequences. They establish the 'burning platform' that justifies investment in solutions.

---

### Solution Approach Specification

**Description:** Information describing how the seller solves the business problem through products, services, technology, methodology, or approach.

**Definition:** An information content entity that specifies how the seller addresses the business problem through specific products, services, technology platforms, methodologies, processes, or approaches. Describes the mechanism of value delivery including implementation approach, technical architecture, and change management.

**Example:** Solution approach: 'Deploy unified revenue operations platform (Salesforce Revenue Cloud) with automated pipeline analytics, AI-powered forecasting, and real-time dashboards. Implementation includes: (1) data integration from existing CRM, marketing automation, and customer success systems; (2) custom pipeline stages mapped to sales process; (3) forecasting models trained on historical data; (4) executive dashboards with drill-down capabilities; (5) sales team training and adoption program. Delivered in 8-week implementation with ongoing optimization support.'

**Scope Note:** Solution approach specifications bridge the gap between problem and outcome by explaining the HOW. They demonstrate methodology, differentiation, and feasibility while building confidence in the seller's capability.

---

### Target Buyer Specification

**Description:** Information describing for whom the seller solves the problem, including industry, business function, company profile, and buyer personas.

**Definition:** An information content entity that specifies the target customer profile including industry verticals, company size and stage, business functions, organizational roles, and buyer personas. Defines WHO experiences the problem and WHO benefits from the solution, enabling precise targeting and personalized positioning.

**Example:** Target buyer: 'VP Sales, CRO, or Head of Revenue Operations at B2B SaaS companies with $10M-$100M ARR, 50-500 employees, Series B through growth stage. Primary industries: Enterprise Software, MarTech, FinTech. Companies experiencing hypergrowth (>50% YoY) with distributed sales teams (5+ regions). Buyer personas include data-driven sales leaders frustrated by forecast unpredictability and RevOps leaders responsible for sales tech stack optimization.'

**Scope Note:** Target buyer specifications enable account-based marketing, personalized messaging, and qualification criteria (ICP definition). They ensure sales offerings resonate with specific audiences by using their language, addressing their contexts, and speaking to their priorities.

---

### Outcome Specification

**Description:** Information describing the value, benefits, outcomes, impacts, and results that customers achieve through the solution.

**Definition:** An information content entity that specifies the measurable business outcomes, value delivered, benefits realized, and impacts achieved when customers successfully adopt the solution. Includes quantitative metrics (revenue growth, cost reduction, efficiency gains, risk mitigation) and qualitative benefits (strategic capabilities, competitive advantages, organizational transformation).

**Example:** Outcomes:
1. Forecast accuracy improves from ±20% variance to ±5%, enabling confident resource allocation and investor reporting
2. Sales leadership saves 15 hours/week on manual reporting, redirecting time to coaching and strategy
3. Pipeline visibility gaps eliminated—real-time dashboards replace end-of-quarter scrambles
4. Revenue predictability increases—board and investor confidence strengthened
5. Data-driven sales culture—reps self-serve analytics, managers coach with insights
6. Typical ROI: 300% in first year through improved forecast accuracy and sales productivity gains

**Scope Note:** Outcome specifications are the 'why buy' answer. They quantify value in customer terms (not vendor features), connect to strategic priorities, and provide proof points through metrics, benchmarks, and customer success stories. Strong outcome specifications differentiate offerings by demonstrating business impact.

---

## Offering Collateral Types

### Solution Brief

**Description:** Concise document (typically 2-4 pages) articulating a sales offering's value proposition.

**Definition:** An information content entity in document form that concisely articulates a sales offering's complete value proposition including problem, solution approach, target buyers, and outcomes. Typically 2-4 pages, solution briefs are sales enablement assets used in early-stage conversations to establish relevance and differentiation.

**Example:** Solution brief titled 'Revenue Operations Platform for SaaS Scale-Ups' containing: executive summary, business challenge section, solution overview with architecture diagram, key capabilities, customer success story, expected outcomes with metrics, and call-to-action. Used by account executives in discovery calls and sent as follow-up after initial meetings.

---

### Case Study

**Also known as:** Customer Success Story

**Description:** Document detailing how a specific customer achieved outcomes using the seller's offering.

**Definition:** An information content entity documenting a specific customer's journey from business challenge through solution implementation to achieved outcomes. Case studies provide social proof, demonstrate real-world applicability, and quantify value through actual customer results.

**Example:** Case study: 'How Acme SaaS Improved Forecast Accuracy by 40% with Revenue Cloud': includes customer background, business challenges they faced, solution deployed, implementation approach, quantified results (40% forecast accuracy improvement, 12 hours/week saved, $2M additional revenue from better pipeline visibility), customer testimonial from VP Sales, and lessons learned.

---

### Use Case

**Description:** Document describing a specific scenario or application pattern for an offering.

**Definition:** An information content entity describing a specific business scenario, application pattern, workflow, or implementation approach for an offering. Use cases connect offerings to real-world situations, helping prospects understand applicability to their contexts.

**Example:** Use case: 'Quarterly Business Review Automation': describes how RevOps teams use the platform to automatically generate QBR materials including pipeline health analysis, win/loss trends, rep performance metrics, and territory coverage gaps. Includes workflow diagram, dashboard screenshots, and time-savings quantification.

---

### Sales Collateral

**Description:** Information assets used by sales teams during customer engagement including presentations, battle cards, ROI calculators, and demo scripts.

**Definition:** An information content entity designed for use by sales teams during customer interactions. Sales collateral includes presentations, pitch decks, battle cards, competitive positioning guides, ROI calculators, demo scripts, objection handling guides, and proposal templates. Optimized for sales conversations and buyer engagement.

**Example:** Sales collateral package including: (1) discovery deck with qualification questions, (2) product demo script with use case scenarios, (3) competitive battle card for displacing incumbent, (4) ROI calculator with industry benchmarks, (5) pricing proposal template, (6) objection handling playbook addressing common concerns (implementation time, data security, change management).

---

### Marketing Collateral

**Description:** Information assets used for marketing campaigns including whitepapers, ebooks, webinar content, and demand generation materials.

**Definition:** An information content entity designed for marketing campaigns, lead generation, and buyer education. Marketing collateral includes whitepapers, ebooks, infographics, webinar presentations, blog posts, email templates, social media content, and video scripts. Optimized for awareness, education, and demand generation rather than direct sales conversations.

**Example:** Marketing collateral for demand generation campaign: (1) gated ebook 'The Revenue Operations Playbook for SaaS Growth', (2) webinar series on forecast accuracy, (3) infographic showing cost of inaccurate forecasting, (4) email nurture sequence (5 touches over 3 weeks), (5) LinkedIn ad creative with customer testimonial, (6) landing page with demo request form.

---

## Relationships

### Offering Composition and Relationships

**offering specifies problem**
Relates a sales offering to the business problem specification it addresses.
*Example:* The 'RevOps Acceleration' sales offering specifies problem of 'Pipeline visibility and forecast accuracy challenges in scaling SaaS companies'.

**offering specifies approach**
Relates a sales offering to the solution approach specification describing how the problem is solved.
*Example:* The 'RevOps Acceleration' sales offering specifies approach using 'Revenue Cloud platform implementation with data integration and analytics dashboards'.

**offering targets buyer**
Relates a sales offering to the target buyer specification defining for whom the offering is designed.
*Example:* The 'RevOps Acceleration' sales offering targets buyer 'VP Sales at B2B SaaS companies with $10M-$100M ARR'.

**offering specifies outcomes**
Relates a sales offering to the outcome specification describing the value and benefits delivered.
*Example:* The 'RevOps Acceleration' sales offering specifies outcomes including '40% improvement in forecast accuracy and 15 hours/week saved in reporting'.

**solution includes product**
Relates a solution offering to product offerings that are included as components.
*Example:* The 'Financial Services Cloud Migration' solution includes products: AWS EC2, AWS RDS, AWS S3, and AWS Security Services.
*Note:* Solutions compose multiple products. This relation enables modeling solution bundles and understanding dependencies.

**solution includes service**
Relates a solution offering to service offerings that are included as components.
*Example:* The 'Financial Services Cloud Migration' solution includes services: Migration Assessment, Architecture Design, Data Migration, Testing, Training, and 90-day Managed Support.
*Note:* Solutions typically pair products with services. Services ensure successful implementation, adoption, and value realization.

**offering coded in collateral**
Relates a sales offering to the collateral assets (solution briefs, case studies, use cases) in which it is documented and codified.
*Example:* The 'RevOps Acceleration' sales offering is coded in collateral: solution brief, two customer case studies, three use case documents, sales presentation deck, and ROI calculator.
*Note:* Sales offerings are abstract value propositions that are made tangible through collateral. This relation tracks which documents articulate which offerings.

**collateral supports offering**
Relates collateral assets to the offerings they support through education, proof points, or sales enablement.
*Example:* The case study 'How Acme SaaS Improved Forecasts by 40%' supports offering 'Revenue Cloud Enterprise Edition' by providing social proof and quantified outcomes.

---

## Additional Notes

- **Offering**: Related to gtm:offers property in gtm_organizations.ttl. Organizations offer Offerings to customers.
- **Sales Offering**: Sales offerings integrate problem-solution-buyer-outcome frameworks. They are the primary value articulation mechanism in B2B sales.
- **Solution Offering**: Solutions compose products and services into outcome-oriented bundles. This reflects the shift from product-centric to outcome-centric selling in modern B2B GTM.
