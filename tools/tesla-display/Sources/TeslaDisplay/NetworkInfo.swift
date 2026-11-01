import Darwin
import Foundation

enum NetworkInfo {
    struct Interface {
        let name: String
        let address: String

        /// Étiquette lisible pour l'affichage console.
        var label: String {
            if name.hasPrefix("en") { return "Wi-Fi / Ethernet (\(name))" }
            if name.hasPrefix("bridge") { return "Partage de connexion (\(name))" }
            if name.hasPrefix("utun") || name.hasPrefix("ipsec") { return "VPN (\(name))" }
            return name
        }

        /// Les adresses de hotspot / LAN privé sont celles à donner à la Tesla.
        var isLikelyReachable: Bool {
            address.hasPrefix("192.168.") || address.hasPrefix("10.") || address.hasPrefix("172.")
        }
    }

    static func localIPv4Addresses() -> [Interface] {
        var results: [Interface] = []
        var ifaddrList: UnsafeMutablePointer<ifaddrs>?

        guard getifaddrs(&ifaddrList) == 0, let head = ifaddrList else { return results }
        defer { freeifaddrs(ifaddrList) }

        var cursor: UnsafeMutablePointer<ifaddrs>? = head
        while let current = cursor {
            let interface = current.pointee
            cursor = interface.ifa_next

            guard let sockaddrPtr = interface.ifa_addr else { continue }
            guard sockaddrPtr.pointee.sa_family == UInt8(AF_INET) else { continue }

            let flags = Int32(bitPattern: interface.ifa_flags)
            guard (flags & IFF_UP) == IFF_UP, (flags & IFF_LOOPBACK) == 0 else { continue }

            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            let result = getnameinfo(
                sockaddrPtr,
                socklen_t(sockaddrPtr.pointee.sa_len),
                &hostname,
                socklen_t(hostname.count),
                nil,
                0,
                NI_NUMERICHOST
            )
            guard result == 0 else { continue }

            let address = String(cString: hostname)
            guard !address.isEmpty else { continue }
            results.append(Interface(name: String(cString: interface.ifa_name), address: address))
        }

        // Les adresses privées d'abord : ce sont celles utilisables depuis la Tesla.
        return results.sorted { lhs, rhs in
            if lhs.isLikelyReachable != rhs.isLikelyReachable { return lhs.isLikelyReachable }
            return lhs.name < rhs.name
        }
    }
}
