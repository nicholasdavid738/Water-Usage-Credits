(define-fungible-token water-credits)

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-oracle (err u101))
(define-constant err-invalid-amount (err u102))
(define-constant err-insufficient-balance (err u103))
(define-constant err-farmer-not-registered (err u104))
(define-constant err-oracle-exists (err u105))
(define-constant err-invalid-practice (err u106))

(define-data-var token-name (string-ascii 32) "Water Credits")
(define-data-var token-symbol (string-ascii 10) "WC")
(define-data-var token-uri (optional (string-utf8 256)) none)
(define-data-var total-supply uint u0)

(define-map farmers principal {
    registered: bool,
    total-earned: uint,
    total-burned: uint,
    conservation-score: uint,
    practices-completed: uint,
    loyalty-tier: uint
})

(define-map oracles principal {
    authorized: bool,
    reports-count: uint
})

(define-map practice-rates (string-ascii 50) uint)

(define-map farmer-balances principal uint)

(define-public (get-name)
    (ok (var-get token-name)))

(define-public (get-symbol)
    (ok (var-get token-symbol)))

(define-public (get-decimals)
    (ok u6))

(define-public (get-balance (who principal))
    (ok (default-to u0 (map-get? farmer-balances who))))

(define-public (get-total-supply)
    (ok (var-get total-supply)))

(define-public (get-token-uri)
    (ok (var-get token-uri)))

(define-public (transfer (amount uint) (from principal) (to principal) (memo (optional (buff 34))))
    (begin
        (asserts! (or (is-eq tx-sender from) (is-eq tx-sender contract-caller)) (err u4))
        (asserts! (> amount u0) err-invalid-amount)
        (let ((from-balance (unwrap! (get-balance from) (err u1))))
            (asserts! (>= from-balance amount) err-insufficient-balance)
            (try! (ft-transfer? water-credits amount from to))
            (map-set farmer-balances from (- from-balance amount))
            (map-set farmer-balances to (+ (default-to u0 (map-get? farmer-balances to)) amount))
            (print {operation: "transfer", from: from, to: to, amount: amount, memo: memo})
            (ok true))))

(define-public (register-farmer)
    (begin
        (asserts! (is-none (map-get? farmers tx-sender)) (err u107))
        (map-set farmers tx-sender {
            registered: true,
            total-earned: u0,
            total-burned: u0,
            conservation-score: u100,
            practices-completed: u0,
            loyalty-tier: u0
        })
        (print {operation: "farmer-registered", farmer: tx-sender})
        (ok true)))

(define-public (authorize-oracle (oracle principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (is-none (map-get? oracles oracle)) err-oracle-exists)
        (map-set oracles oracle {
            authorized: true,
            reports-count: u0
        })
        (print {operation: "oracle-authorized", oracle: oracle})
        (ok true)))

(define-public (revoke-oracle (oracle principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-delete oracles oracle)
        (print {operation: "oracle-revoked", oracle: oracle})
        (ok true)))

(define-public (set-practice-rate (practice (string-ascii 50)) (rate uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-set practice-rates practice rate)
        (print {operation: "practice-rate-set", practice: practice, rate: rate})
        (ok true)))

(define-public (report-sustainable-practice (farmer principal) (practice (string-ascii 50)) (efficiency-score uint))
    (let ((oracle-info (unwrap! (map-get? oracles tx-sender) err-not-oracle))
          (farmer-info (unwrap! (map-get? farmers farmer) err-farmer-not-registered))
          (practice-rate (default-to u0 (map-get? practice-rates practice))))
        (asserts! (get authorized oracle-info) err-not-oracle)
        (asserts! (> practice-rate u0) err-invalid-practice)
        (asserts! (<= efficiency-score u100) err-invalid-amount)
        
        (let ((base-credits (* practice-rate (/ efficiency-score u10)))
              (practices-done (+ (get practices-completed farmer-info) u1))
              (new-tier (calculate-tier practices-done))
              (tier-multiplier (get-tier-multiplier new-tier))
              (credits-to-mint (/ (* base-credits tier-multiplier) u100)))
            (try! (ft-mint? water-credits credits-to-mint farmer))
            (map-set farmer-balances farmer (+ (default-to u0 (map-get? farmer-balances farmer)) credits-to-mint))
            (var-set total-supply (+ (var-get total-supply) credits-to-mint))
            
            (map-set farmers farmer (merge farmer-info {
                total-earned: (+ (get total-earned farmer-info) credits-to-mint),
                conservation-score: (if (> (+ (get conservation-score farmer-info) (/ efficiency-score u20)) u100)
                                    u100
                                    (+ (get conservation-score farmer-info) (/ efficiency-score u20))),
                practices-completed: practices-done,
                loyalty-tier: new-tier
            }))
            
            (map-set oracles tx-sender (merge oracle-info {
                reports-count: (+ (get reports-count oracle-info) u1)
            }))
            
            (print {
                operation: "credits-earned",
                farmer: farmer,
                practice: practice,
                efficiency: efficiency-score,
                credits: credits-to-mint,
                tier: new-tier,
                multiplier: tier-multiplier,
                oracle: tx-sender
            })
            (ok credits-to-mint))))

(define-public (burn-for-water-usage (farmer principal) (usage-amount uint) (water-type (string-ascii 30)))
    (let ((oracle-info (unwrap! (map-get? oracles tx-sender) err-not-oracle))
          (farmer-info (unwrap! (map-get? farmers farmer) err-farmer-not-registered))
          (farmer-balance (default-to u0 (map-get? farmer-balances farmer))))
        (asserts! (get authorized oracle-info) err-not-oracle)
        (asserts! (> usage-amount u0) err-invalid-amount)
        
        (let ((credits-to-burn (if (is-eq water-type "groundwater") 
                                   (* usage-amount u2) 
                                   usage-amount)))
            (asserts! (>= farmer-balance credits-to-burn) err-insufficient-balance)
            
            (try! (ft-burn? water-credits credits-to-burn farmer))
            (map-set farmer-balances farmer (- farmer-balance credits-to-burn))
            (var-set total-supply (- (var-get total-supply) credits-to-burn))
            
            (map-set farmers farmer (merge farmer-info {
                total-burned: (+ (get total-burned farmer-info) credits-to-burn),
                conservation-score: (if (< (- (get conservation-score farmer-info) (/ usage-amount u50)) u0)
                                    u0
                                    (- (get conservation-score farmer-info) (/ usage-amount u50)))
            }))
            
            (print {
                operation: "credits-burned",
                farmer: farmer,
                usage: usage-amount,
                water-type: water-type,
                credits-burned: credits-to-burn,
                oracle: tx-sender
            })
            (ok credits-to-burn))))

(define-public (emergency-mint (farmer principal) (amount uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (> amount u0) err-invalid-amount)
        (try! (ft-mint? water-credits amount farmer))
        (map-set farmer-balances farmer (+ (default-to u0 (map-get? farmer-balances farmer)) amount))
        (var-set total-supply (+ (var-get total-supply) amount))
        (print {operation: "emergency-mint", farmer: farmer, amount: amount})
        (ok true)))

(define-read-only (get-farmer-info (farmer principal))
    (map-get? farmers farmer))

(define-read-only (get-oracle-info (oracle principal))
    (map-get? oracles oracle))

(define-read-only (get-practice-rate (practice (string-ascii 50)))
    (map-get? practice-rates practice))

(define-read-only (is-farmer-registered (farmer principal))
    (match (map-get? farmers farmer)
        farmer-info (get registered farmer-info)
        false))

(define-read-only (is-oracle-authorized (oracle principal))
    (match (map-get? oracles oracle)
        oracle-info (get authorized oracle-info)
        false))

(define-read-only (get-conservation-score (farmer principal))
    (match (map-get? farmers farmer)
        farmer-info (get conservation-score farmer-info)
        u0))

(define-read-only (calculate-water-allowance (farmer principal))
    (let ((farmer-info (unwrap! (map-get? farmers farmer) (err u404)))
          (balance (default-to u0 (map-get? farmer-balances farmer)))
          (conservation-score (get conservation-score farmer-info)))
        (ok (* balance (+ u1 (/ conservation-score u100))))))

(define-read-only (calculate-tier (practices-completed uint))
    (if (>= practices-completed u50)
        u4
        (if (>= practices-completed u25)
            u3
            (if (>= practices-completed u10)
                u2
                (if (>= practices-completed u3)
                    u1
                    u0)))))

(define-read-only (get-tier-multiplier (tier uint))
    (if (is-eq tier u4)
        u150
        (if (is-eq tier u3)
            u130
            (if (is-eq tier u2)
                u115
                (if (is-eq tier u1)
                    u105
                    u100)))))

(define-read-only (get-farmer-tier (farmer principal))
    (match (map-get? farmers farmer)
        farmer-info (ok (get loyalty-tier farmer-info))
        (err u404)))

(define-read-only (get-tier-info (farmer principal))
    (match (map-get? farmers farmer)
        farmer-info (ok {
            tier: (get loyalty-tier farmer-info),
            practices: (get practices-completed farmer-info),
            multiplier: (get-tier-multiplier (get loyalty-tier farmer-info)),
            next-tier-at: (get-next-tier-threshold (get loyalty-tier farmer-info))
        })
        (err u404)))

(define-read-only (get-next-tier-threshold (current-tier uint))
    (if (is-eq current-tier u4)
        u0
        (if (is-eq current-tier u3)
            u50
            (if (is-eq current-tier u2)
                u25
                (if (is-eq current-tier u1)
                    u10
                    u3)))))

(begin
    (map-set practice-rates "drip-irrigation" u50)
    (map-set practice-rates "cover-crops" u30)
    (map-set practice-rates "soil-moisture-monitoring" u40)
    (map-set practice-rates "rainwater-harvesting" u60)
    (map-set practice-rates "crop-rotation" u25)
    (map-set practice-rates "precision-farming" u45)
)
