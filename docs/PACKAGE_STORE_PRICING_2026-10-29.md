# Package selection and store pricing

The package screen presents Standard, Student and Premium without a billing-country field, phone-locale guess, country-confirmation action or regional-price API request. Old account settings such as `billing_country` and cached `mobile_prices_*` are ignored. The unused mobile regional-price repository method has been removed; the historical API/admin catalogue is not changed by this UI repair.

Package benefits remain visible while store setup is on hold. Cards open the existing package-details sheet. They do not present invented dollar amounts, convert historical NGN amounts, calculate annual charges from unverified catalogue data, or activate paid access.

When enabled, the existing native billing service queries Apple/Google products and the billing panel displays the store's formatted product price. The user's storefront determines available currency and checkout price; device locale and manually entered country are not purchase authorities. Store accounts, product configuration and genuine purchase acceptance remain deferred.

The requested commercial base currency is USD. Exact monthly USD amounts for Student, Standard and Premium require the owner's answer; previous NGN amounts are not dollar prices. Set approved USD prices through the store consoles during final store setup. Other storefronts may charge their local currency. No store configuration has been activated by this change.

Validation: `test/features/settings/reliability_repair_test.dart` reproduces the former country control and asserts its removal, no regional request, all three packages, ignored legacy prices and retained package-details behavior. See the workspace implementation report for full local/hosted build evidence and the replacement APK identity.
