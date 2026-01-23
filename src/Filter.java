import java.io.ByteArrayOutputStream;
import java.math.BigInteger;
import java.nio.charset.StandardCharsets;
import java.security.KeyFactory;
import java.security.Signature;
import java.security.interfaces.RSAPrivateKey;
import java.security.spec.RSAPrivateKeySpec;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Base64;
import javax.crypto.Cipher;
import javax.crypto.spec.SecretKeySpec;

public class Filter {
    private static final byte[] ENCRYPTION_KEY = "burpr0x!".getBytes();
    private static final String N = "772466485993532616265602004787593990571998354762769517556824947462364733846988896764791786418284048308408035898123800088385145599914482866982121337242267111996730589833008965586904619624210600143815034555107626281306790690247380277401223658213686836260051740513369525229945146545746232288644834011082272373923840674183841152721282934896147636659685196110193170859036230613942473057350558696079781329724723538612065451271117946653171891463701206005132474249143377280956637274812017722966962038177658826682928177419967120615723412715280627140352666513761887655683881127941062521608622150057375302773817128043341551104335925307524362463158532014345920401529131689972511711145366384313357331219918007902162272947810092434401421074436297130543420857679173250879221703239461167245128718027210585470097741338476167664231386224393829173753597329684981549442031004886309176804274536524421269896699613148427017011648805968328213879561704664823249805341430850708344955922886822191380206543393525391519722222586339612770531074577303349625790208047047035933996137831086461496793235410445769659982355567180073509405077094784975713575937671560399734544873967339281900443458904052345698752817504449813508664835247206727493828740500751727305948870197";
    private static final String D = "174973907633458835290948040970319556739571777415098547204343597434713283701703620435377482481337667228257584157157755349071173328512603539380038623241244720960548478051650488947275570720683070008314908951745925387887747498309693153760794134705314266510222745745471574866694168187002804802248082165715799218623058956135604649467437404344619248153150536891463106663448019339670354342377115886343658602617811632065796597709992003266343237084069218962512650567290743179208710809841530785624068105905783683752812438680431083289445871214098004331881766550144120454836614665674124130388635363498508268148943577914817665229458767012826384170293442481353885513942286386871422229921740675582649721394004737713146579092336428734122223073166081868987285302826609579340630764882890999436799814488695761863240374337775451144202336101045005062769951606330931316728620859403340949196048544016831331215882019606910236181120045619447482208762438586388152397180820131522205873078063910211185803468590525972907163613199413004903986557077623758471248380271780715344796370488885220077075150724843009236460156571650622249128893865976236126703679474153844433204143676260363864471833141144466790653534160506805002383442253160746350344972938442854944399195933";
    private static final String KEY_2048 = "30820238020100300D06092A864886F70D0101010500048202223082021E02010002820101009D9DF9EB49890DE8F193C89598584BC947BA83727B2D89AA8BE3A4689130FE2E948967D40B656762F9989E59C9655E28E33FD4B4A544126FDD90A566BB61C2D7C74A6829265767B56E28FD2214D4BEB3B1DA4722BC394E2E6AFA0F1689FA9DB442643DDDA84997C5AD15B57EE5BD1A357CABF6ED4CAAA5FB8872E07C8F5FAE1C573C1214DD273C6D8887D7E993208D75118CC2305D60AA337B0999B69988322A8FAA9FBFF49AB70B71723E1CBD79D12640AF19E6FBC28C05E6630414DBAD9AEF912D0AC53E40B7F48EE29BFE1DEFCFB0BDB1B6C5BF8B06DCCA15FA1FC3F468952D481070C92C386D3CE6187B062038A6CA822D352ECEBEAC195918F9BB5C3AC3020100028201005DAD71C754BA3F692E835E1903259F4D6EF33C82C3110A9C316E47DDDA455B1D062D306787AA6A2B1A1B8A29E517F941A5E6DF1DCA87CDC96CCF366EFB799C1B31185915F3F2C8F1BD1A61706B1F1284AC7506087004432235748F991EC2B40E59D3482DC08294D0E9115900A5BCA1A21E89FA45896677262B2FD39A54805273162D655F1AB4392CE4E01A4DD63F7EF387B79D53B73BBE45EA7D9BE64A627CFB3DAE2843E85ED3697672BD4832F5EEB4C18C4D15FEB550E0B5A7018A3CD39A9FD4BDA35A6F88BD00CCBC787419AD57C54FA823EC3D7662710B03C2622E9E2DE546B21CA1C76672B1CC6BD92871A0F96051E31CB060E0DDB4022BEB2897A88761020100020100020100020100020100";
    private static final String KEY_1024 = "30820136020100300D06092A864886F70D0101010500048201203082011C020100028181008D187233EB87AB60DB5BAE8453A7DE035428EB177EC8C60341CAB4CF487052751CA8AFF226EA3E98F0CEEF8AAE12E3716B8A20A24BDE20703865C9DBD9543F92EA6495763DFD6F7507B8607F2A14F52694BB9793FE12D3D9C5D1C0045262EA5E7FA782ED42568C6B7E31019FFFABAEFB79D327A4A7ACBD4D547ACB2DC9CD04030201000281807172A188DBAD977FE680BE3EC9E0E4E33A4D385208F0383EB02CE3DAF33CD520332DF362BA2588B58292710AC9D2882C4F329DF0C11DD66944FF9B21F98A031ED27C19FE2BCF8A09AD3E254A0FD7AB89E0D1E756BCF37ED24D42D1977EA7C1C78ABF4D13F752AE48B426A2DC98C5D13B2313609FAA6441E835DC61D17A01D1A9020100020100020100020100020100";

    private static byte[] decrypt(byte[] data) throws Exception {
        if (data == null || data.length == 0 || data.length % 8 != 0) {
            throw new IllegalArgumentException("Invalid data length");
        }
        Cipher cipher = Cipher.getInstance("DES");
        cipher.init(Cipher.DECRYPT_MODE, new SecretKeySpec(ENCRYPTION_KEY, "DES"));
        return cipher.doFinal(data);
    }

    private static byte[] encrypt(byte[] data) throws Exception {
        Cipher cipher = Cipher.getInstance("DES");
        cipher.init(Cipher.ENCRYPT_MODE, new SecretKeySpec(ENCRYPTION_KEY, "DES"));
        return cipher.doFinal(data);
    }

    public static void BurpFilter(Object[] obj) {
        try {
            if (obj == null || obj.length == 0 || obj[0] == null) return;

            byte[] data;
            if (obj[0] instanceof byte[]) {
                data = (byte[]) obj[0];
            } else if (obj[0] instanceof String) {
                try {
                    data = Base64.getDecoder().decode(((String) obj[0]).trim().replaceAll("\\s+", ""));
                } catch (Exception e) {
                    return;
                }
            } else {
                return;
            }

            byte[] decoded;
            try {
                decoded = Base64.getDecoder().decode(data);
            } catch (Exception e) {
                decoded = data;
            }

            if (decoded.length == 0 || decoded.length % 8 != 0) return;

            byte[] decrypted;
            try {
                decrypted = decrypt(decoded);
            } catch (Exception e) {
                return;
            }

            String[] parts = new String(decrypted).split("\u0000");

            if (parts.length >= 2 && parts.length >= 3 && parts.length <= 7 
                && !"license".equals(parts[1]) && !"activation".equals(parts[1])) {
                System.out.println("\n╔════════════════════════════════════════════════════════════════════╗");
                System.out.println("║                    MANUAL ACTIVATION REQUIRED                      ║");
                System.out.println("╠════════════════════════════════════════════════════════════════════╣");
                System.out.println("║  1. COPY the Activation Request from Burp window                   ║");
                System.out.println("║  2. Run: docker compose exec burpsuite java -cp /app/loader.jar    ║");
                System.out.println("║         Keygen -activate \"<REQUEST>\"                               ║");
                System.out.println("║  3. PASTE the response into Burp and click Next                    ║");
                System.out.println("╚════════════════════════════════════════════════════════════════════╝\n");
            }

            obj[0] = Arrays.copyOf(parts, parts.length - 2);
        } catch (Exception ignored) {}
    }

    public static byte[] BountyFilter(String url, byte[] data) throws Exception {
        if (url.equals("https://api.licensespring.com/api/v4/activate_license")) {
            String json = getText(new String(data), "hardware_id") + "#" + getText(new String(data), "license_key") + "#2099-12-31t14:58:33.213z";
            return ("{\"license_signature\":\"" + sign(json.toLowerCase()) + "\",\"license_type\":\"perpetual\",\"is_trial\":false,\"validity_period\":\"2099-12-31T20:28:33.213+05:30\",\"max_activations\":99,\"times_activated\":99,\"transfer_count\":99,\"prevent_vm\":false,\"customer\":{\"email\":\"user@example.com\"},\"product_details\":{\"product_name\":\"Burp Bounty Pro\",\"short_code\":\"burpbountyprostripe\"},\"allow_overages\":false,\"is_floating_cloud\":false}\n").getBytes();
        }
        if (url.equals("https://api.licensespring.com/api/v4/product_details?product=burpbountyprostripe")) {
            return "{\"product_name\":\"Burp Bounty Pro\",\"short_code\":\"burpbountyprostripe\",\"allow_trial\":false,\"authorization_method\":\"license-key\"}".getBytes();
        }
        if (url.startsWith("https://api.licensespring.com/api/v4/check_license?app_name=Burp")) {
            String json = getParam(url, "hardware_id") + "#" + getParam(url, "license_key") + "#2099-12-31t14:58:33.213z";
            return ("{\"license_signature\":\"" + sign(json.toLowerCase()) + "\",\"license_type\":\"perpetual\",\"is_trial\":false,\"validity_period\":\"2099-12-31T20:28:33.213+05:30\",\"license_active\":true,\"license_enabled\":true,\"is_expired\":false}").getBytes();
        }
        return null;
    }

    public static String generateActivationResponse(String request) {
        try {
            byte[] decoded = Base64.getDecoder().decode(request.trim().replaceAll("\\s+", ""));
            if (decoded.length % 8 != 0) return null;
            String[] parts = new String(decrypt(decoded)).split("\u0000");
            if (parts.length < 3) return null;

            ArrayList<String> response = new ArrayList<>();
            response.add(String.valueOf(Math.random()));
            response.add(parts[0]);
            response.add("activation");
            response.add(parts[1]);
            response.add("True");
            response.add("");
            response.add(parts[2]);
            response.add(parts.length > 3 ? parts[3] : "");
            response.add(signActivation(response, KEY_2048, "SHA256withRSA"));
            response.add(signActivation(response, KEY_1024, "SHA1withRSA"));

            ByteArrayOutputStream out = new ByteArrayOutputStream();
            for (int i = 0; i < response.size() - 1; i++) {
                out.write(response.get(i).getBytes());
                out.write(0);
            }
            out.write(response.get(response.size() - 1).getBytes());
            return Base64.getEncoder().encodeToString(encrypt(out.toByteArray()));
        } catch (Exception e) {
            return null;
        }
    }

    private static String getText(String json, String key) {
        String prefix = "\"" + key + "\":\"";
        int start = json.indexOf(prefix);
        if (start == -1) return null;
        start += prefix.length();
        return json.substring(start, json.indexOf("\"", start));
    }

    private static String getParam(String url, String key) {
        for (String param : url.substring(url.indexOf('?') + 1).split("&")) {
            if (param.startsWith(key + "=")) return param.substring(key.length() + 1);
        }
        return null;
    }

    private static String sign(String data) throws Exception {
        Signature sig = Signature.getInstance("SHA256withRSA");
        sig.initSign(getKey(new BigInteger(N), new BigInteger(D)));
        sig.update(data.getBytes(StandardCharsets.UTF_8));
        return Base64.getEncoder().encodeToString(sig.sign());
    }

    private static String signActivation(ArrayList<String> list, String keyHex, String algo) throws Exception {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        for (String s : list) {
            out.write(s.getBytes());
            out.write(0);
        }
        Signature sig = Signature.getInstance(algo);
        sig.initSign(getKeyFromHex(keyHex));
        sig.update(out.toByteArray());
        return Base64.getEncoder().encodeToString(sig.sign());
    }

    private static RSAPrivateKey getKey(BigInteger n, BigInteger d) throws Exception {
        return (RSAPrivateKey) KeyFactory.getInstance("RSA").generatePrivate(new RSAPrivateKeySpec(n, d));
    }

    private static RSAPrivateKey getKeyFromHex(String hex) throws Exception {
        return (RSAPrivateKey) KeyFactory.getInstance("RSA").generatePrivate(
            new java.security.spec.PKCS8EncodedKeySpec(new BigInteger(hex, 16).toByteArray()));
    }
}
