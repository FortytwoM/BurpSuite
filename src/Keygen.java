import java.io.ByteArrayOutputStream;
import java.math.BigInteger;
import java.security.KeyFactory;
import java.security.Signature;
import java.security.interfaces.RSAPrivateKey;
import java.security.spec.PKCS8EncodedKeySpec;
import java.util.ArrayList;
import java.util.Base64;
import java.util.List;
import java.util.Random;
import javax.crypto.Cipher;
import javax.crypto.spec.SecretKeySpec;

public class Keygen {
    private static final String KEY_2048 = "30820238020100300D06092A864886F70D0101010500048202223082021E02010002820101009D9DF9EB49890DE8F193C89598584BC947BA83727B2D89AA8BE3A4689130FE2E948967D40B656762F9989E59C9655E28E33FD4B4A544126FDD90A566BB61C2D7C74A6829265767B56E28FD2214D4BEB3B1DA4722BC394E2E6AFA0F1689FA9DB442643DDDA84997C5AD15B57EE5BD1A357CABF6ED4CAAA5FB8872E07C8F5FAE1C573C1214DD273C6D8887D7E993208D75118CC2305D60AA337B0999B69988322A8FAA9FBFF49AB70B71723E1CBD79D12640AF19E6FBC28C05E6630414DBAD9AEF912D0AC53E40B7F48EE29BFE1DEFCFB0BDB1B6C5BF8B06DCCA15FA1FC3F468952D481070C92C386D3CE6187B062038A6CA822D352ECEBEAC195918F9BB5C3AC3020100028201005DAD71C754BA3F692E835E1903259F4D6EF33C82C3110A9C316E47DDDA455B1D062D306787AA6A2B1A1B8A29E517F941A5E6DF1DCA87CDC96CCF366EFB799C1B31185915F3F2C8F1BD1A61706B1F1284AC7506087004432235748F991EC2B40E59D3482DC08294D0E9115900A5BCA1A21E89FA45896677262B2FD39A54805273162D655F1AB4392CE4E01A4DD63F7EF387B79D53B73BBE45EA7D9BE64A627CFB3DAE2843E85ED3697672BD4832F5EEB4C18C4D15FEB550E0B5A7018A3CD39A9FD4BDA35A6F88BD00CCBC787419AD57C54FA823EC3D7662710B03C2622E9E2DE546B21CA1C76672B1CC6BD92871A0F96051E31CB060E0DDB4022BEB2897A88761020100020100020100020100020100";
    private static final String KEY_1024 = "30820136020100300D06092A864886F70D0101010500048201203082011C020100028181008D187233EB87AB60DB5BAE8453A7DE035428EB177EC8C60341CAB4CF487052751CA8AFF226EA3E98F0CEEF8AAE12E3716B8A20A24BDE20703865C9DBD9543F92EA6495763DFD6F7507B8607F2A14F52694BB9793FE12D3D9C5D1C0045262EA5E7FA782ED42568C6B7E31019FFFABAEFB79D327A4A7ACBD4D547ACB2DC9CD04030201000281807172A188DBAD977FE680BE3EC9E0E4E33A4D385208F0383EB02CE3DAF33CD520332DF362BA2588B58292710AC9D2882C4F329DF0C11DD66944FF9B21F98A031ED27C19FE2BCF8A09AD3E254A0FD7AB89E0D1E756BCF37ED24D42D1977EA7C1C78ABF4D13F752AE48B426A2DC98C5D13B2313609FAA6441E835DC61D17A01D1A9020100020100020100020100020100";
    private static final byte[] KEY = "burpr0x!".getBytes();

    public static void main(String[] args) {
        if (args.length == 0) {
            System.err.println("Usage: Keygen <name> | Keygen -activate <request>");
            System.exit(1);
        }
        if ("-activate".equals(args[0]) && args.length > 1) {
            String r = Filter.generateActivationResponse(args[1]);
            if (r != null) System.out.println(r);
            else System.exit(1);
        } else {
            System.out.println(generateLicense(args[0]));
        }
    }

    public static String generateLicense(String name) {
        ArrayList<String> l = new ArrayList<>();
        l.add(randomStr());
        l.add("license");
        l.add(name);
        l.add("4102415999000");
        l.add("1");
        l.add("full");
        l.add(sign(KEY_2048, sigBytes(l), "SHA256withRSA"));
        l.add(sign(KEY_1024, sigBytes(l), "SHA1withRSA"));
        return encode(l);
    }

    private static byte[] sigBytes(List<String> l) {
        try {
            ByteArrayOutputStream o = new ByteArrayOutputStream();
            for (String s : l) { o.write(s.getBytes()); o.write(0); }
            return o.toByteArray();
        } catch (Exception e) { throw new RuntimeException(e); }
    }

    private static String sign(String key, byte[] data, String algo) {
        try {
            Signature s = Signature.getInstance(algo);
            s.initSign(getKey(key));
            s.update(data);
            return Base64.getEncoder().encodeToString(s.sign());
        } catch (Exception e) { return null; }
    }

    private static RSAPrivateKey getKey(String hex) {
        try {
            return (RSAPrivateKey) KeyFactory.getInstance("RSA")
                .generatePrivate(new PKCS8EncodedKeySpec(new BigInteger(hex, 16).toByteArray()));
        } catch (Exception e) { return null; }
    }

    private static String randomStr() {
        String c = "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890";
        StringBuilder s = new StringBuilder();
        Random r = new Random();
        while (s.length() < 32) s.append(c.charAt((int)(r.nextFloat() * c.length())));
        return s.toString();
    }

    private static String encode(ArrayList<String> l) {
        try {
            ByteArrayOutputStream o = new ByteArrayOutputStream();
            for (int i = 0; i < l.size() - 1; i++) { o.write(l.get(i).getBytes()); o.write(0); }
            o.write(l.get(l.size() - 1).getBytes());
            Cipher c = Cipher.getInstance("DES");
            c.init(Cipher.ENCRYPT_MODE, new SecretKeySpec(KEY, "DES"));
            return Base64.getEncoder().encodeToString(c.doFinal(o.toByteArray()));
        } catch (Exception e) { throw new RuntimeException(e); }
    }
}
