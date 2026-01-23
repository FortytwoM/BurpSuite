import java.lang.instrument.ClassFileTransformer;
import java.lang.instrument.Instrumentation;
import java.security.ProtectionDomain;
import org.objectweb.asm.ClassReader;
import org.objectweb.asm.ClassWriter;
import org.objectweb.asm.Opcodes;
import org.objectweb.asm.tree.*;

public class Loader implements ClassFileTransformer {
    private static final String BIGINT = "java/math/BigInteger";
    private static final String BOUNTY = "feign/okhttp/OkHttpClient";
    private static final String FILTER = "Filter";
    private static final int MIN_CLASS = 110000;
    private static final int MIN_METHOD = 20000;
    private static final String SIG1 = "([Ljava/lang/Object;Ljava/lang/Object;)V";
    private static final String SIG2 = "([Ljava/lang/Object;)V";

    @Override
    public byte[] transform(ClassLoader loader, String className, Class<?> cls,
                           ProtectionDomain pd, byte[] bytes) {
        if (bytes == null || className == null) return null;
        try {
            byte[] r = patchBigInt(className, bytes);
            if (r != null) return r;
            r = patchBounty(className, bytes);
            if (r != null) return r;
            return patchBurp(className, bytes);
        } catch (Exception e) {
            return null;
        }
    }

    private byte[] patchBigInt(String name, byte[] bytes) {
        if (!BIGINT.equals(name)) return null;
        ClassNode cn = read(bytes);
        boolean mod = false;
        for (MethodNode m : cn.methods) {
            if ("oddModPow".equals(m.name) && "(Ljava/math/BigInteger;Ljava/math/BigInteger;)Ljava/math/BigInteger;".equals(m.desc)) {
                InsnList il = new InsnList();
                String check = "784494550650629402578318812038873246103062429392765900863679692401515917483288444551360396993891243581323776031174104716520618196517054075399181152805062167863399993397788108526062574442957397380276947009110814837620187732300913174633871838721345699310979475106228455540662931554176848428161559382213664590949585029191542943085957823265503304336742766067624625736735254354398945046006311244707353417137449868938968730226771591246625865947893595622114503547108373009472960599444147060111971350419883686667465293379976619008764355965580465504280432683151160078556566540083447715822702727667177022111431814347374423107231482768994558297231501807470318213348545623616323683043933536716592761352026200587983508688675808140761791235890894421345168268944272003766511723863509248901907706583412647586304919169213119463168988654772466925970559627610723088498856098005959331457878486945150019623509488580895386399262569844097131075786500942530443065538693113151751368621487717116172049865065084334155464496258411943450302953590604940950912787049251686884076034812543594664806687830000981320979025230888404872529342183959392375396232582878580953197200612251616917416861184388805361800660771481139764435258505831114252491932487115517415875364419";
                String val = "772466485993532616265602004787593990571998354762769517556824947462364733846988896764791786418284048308408035898123800088385145599914482866982121337242267111996730589833008965586904619624210600143815034555107626281306790690247380277401223658213686836260051740513369525229945146545746232288644834011082272373923840674183841152721282934896147636659685196110193170859036230613942473057350558696079781329724723538612065451271117946653171891463701206005132474249143377280956637274812017722966962038177658826682928177419967120615723412715280627140352666513761887655683881127941062521608622150057375302773817128043341551104335925307524362463158532014345920401529131689972511711145366384313357331219918007902162272947810092434401421074436297130543420857679173250879221703239461167245128718027210585470097741338476167664231386224393829173753597329684981549442031004886309176804274536524421269896699613148427017011648805968328213879561704664823249805341430850708344955922886822191380206543393525391519722222586339612770531074577303349625790208047047035933996137831086461496793235410445769659982355567180073509405077094784975713575937671560399734544873967339281900443458904052345698752817504449813508664835247206727493828740500751727305948870197";
                il.add(new LdcInsnNode(check));
                il.add(new VarInsnNode(Opcodes.ALOAD, 2));
                il.add(new MethodInsnNode(Opcodes.INVOKEVIRTUAL, BIGINT, "toString", "()Ljava/lang/String;", false));
                il.add(new MethodInsnNode(Opcodes.INVOKEVIRTUAL, "java/lang/String", "equals", "(Ljava/lang/Object;)Z", false));
                LabelNode skip = new LabelNode();
                il.add(new JumpInsnNode(Opcodes.IFEQ, skip));
                il.add(new TypeInsnNode(Opcodes.NEW, BIGINT));
                il.add(new InsnNode(Opcodes.DUP));
                il.add(new LdcInsnNode(val));
                il.add(new MethodInsnNode(Opcodes.INVOKESPECIAL, BIGINT, "<init>", "(Ljava/lang/String;)V", false));
                il.add(new VarInsnNode(Opcodes.ASTORE, 2));
                il.add(skip);
                m.instructions.insert(il);
                mod = true;
            }
        }
        return mod ? write(cn) : null;
    }

    private byte[] patchBounty(String name, byte[] bytes) {
        if (!BOUNTY.equals(name)) return null;
        ClassNode cn = read(bytes);
        boolean mod = false;
        for (MethodNode m : cn.methods) {
            if ("toFeignResponse".equals(m.name) && "(Lokhttp3/Response;Lfeign/Request;)Lfeign/Response;".equals(m.desc)) {
                for (AbstractInsnNode i : m.instructions.toArray()) {
                    if (i instanceof MethodInsnNode) {
                        MethodInsnNode mi = (MethodInsnNode) i;
                        if ("feign/Response$Builder".equals(mi.owner) && "build".equals(mi.name)) {
                            InsnList il = new InsnList();
                            LabelNode skip = new LabelNode();
                            il.add(new VarInsnNode(Opcodes.ALOAD, 1));
                            il.add(new MethodInsnNode(Opcodes.INVOKEVIRTUAL, "feign/Request", "url", "()Ljava/lang/String;", false));
                            il.add(new VarInsnNode(Opcodes.ALOAD, 1));
                            il.add(new MethodInsnNode(Opcodes.INVOKEVIRTUAL, "feign/Request", "body", "()[B", false));
                            il.add(new MethodInsnNode(Opcodes.INVOKESTATIC, FILTER, "BountyFilter", "(Ljava/lang/String;[B)[B", false));
                            il.add(new VarInsnNode(Opcodes.ASTORE, 2));
                            il.add(new VarInsnNode(Opcodes.ALOAD, 2));
                            il.add(new JumpInsnNode(Opcodes.IFNULL, skip));
                            il.add(new VarInsnNode(Opcodes.ALOAD, 2));
                            il.add(new MethodInsnNode(Opcodes.INVOKEVIRTUAL, "feign/Response$Builder", "body", "([B)Lfeign/Response$Builder;", false));
                            il.add(new IntInsnNode(Opcodes.BIPUSH, 200));
                            il.add(new MethodInsnNode(Opcodes.INVOKEVIRTUAL, "feign/Response$Builder", "status", "(I)Lfeign/Response$Builder;", false));
                            il.add(skip);
                            m.instructions.insertBefore(mi, il);
                            mod = true;
                            break;
                        }
                    }
                }
            }
        }
        return mod ? write(cn) : null;
    }

    private byte[] patchBurp(String name, byte[] bytes) {
        if (!name.startsWith("burp/") || bytes.length <= MIN_CLASS) return null;
        ClassNode cn = read(bytes);
        boolean mod = false;
        for (MethodNode m : cn.methods) {
            if (m.desc == null) continue;
            if (SIG1.equals(m.desc) && m.instructions.size() > MIN_METHOD) {
                System.out.println("[Loader] Patching: " + name + "." + m.name);
                m.instructions.clear();
                m.exceptions.clear();
                m.tryCatchBlocks.clear();
                InsnList il = new InsnList();
                il.add(new VarInsnNode(Opcodes.ALOAD, 0));
                il.add(new MethodInsnNode(Opcodes.INVOKESTATIC, FILTER, "BurpFilter", "([Ljava/lang/Object;)V", false));
                il.add(new InsnNode(Opcodes.RETURN));
                m.instructions.add(il);
                mod = true;
            }
        }
        for (MethodNode m : cn.methods) {
            if (m.desc == null) continue;
            if (SIG1.equals(m.desc) && m.instructions.size() > MIN_METHOD) {
                int exc = 0;
                for (int i = m.instructions.size() - 1; i >= 0; i--) {
                    AbstractInsnNode n = m.instructions.get(i);
                    if (n instanceof TypeInsnNode && n.getOpcode() == Opcodes.NEW && "java/lang/Exception".equals(((TypeInsnNode)n).desc)) {
                        if (++exc == 2) {
                            for (int j = 0; j < 6; j++) {
                                AbstractInsnNode p = m.instructions.get(i - j);
                                if (p instanceof JumpInsnNode) {
                                    m.instructions.insert(p, new JumpInsnNode(Opcodes.GOTO, ((JumpInsnNode)p).label));
                                    break;
                                }
                            }
                            break;
                        }
                    }
                }
                mod = true;
            }
        }
        return mod ? write(cn) : null;
    }

    private ClassNode read(byte[] b) {
        ClassNode cn = new ClassNode();
        new ClassReader(b).accept(cn, 0);
        return cn;
    }

    private byte[] write(ClassNode cn) {
        ClassWriter cw = new ClassWriter(ClassWriter.COMPUTE_FRAMES | ClassWriter.COMPUTE_MAXS);
        cn.accept(cw);
        return cw.toByteArray();
    }

    public static void premain(String args, Instrumentation inst) {
        System.out.println("[Loader] Agent loaded");
        inst.addTransformer(new Loader());
    }
}
